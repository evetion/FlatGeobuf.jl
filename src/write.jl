const MAGIC_BYTES = UInt8[0x66, 0x67, 0x62, 0x03, 0x66, 0x67, 0x62, 0x00]

const reverse_lookup = Dict(
    Int8 => ColumnTypeByte,
    UInt8 => ColumnTypeUByte,
    Bool => ColumnTypeBool,
    Int16 => ColumnTypeShort,
    UInt16 => ColumnTypeUShort,
    Int32 => ColumnTypeInt,
    UInt32 => ColumnTypeUInt,
    Int64 => ColumnTypeLong,
    UInt64 => ColumnTypeULong,
    Float32 => ColumnTypeFloat,
    Float64 => ColumnTypeDouble,
)

function columntype(T::Type)
    S = nonmissingtype(T)
    haskey(reverse_lookup, S) && return reverse_lookup[S]
    S <: AbstractString && return ColumnTypeString  # also for all missing columns, as Union{} <: AbstractString
    S <: Union{Dates.Date,Dates.DateTime} && return ColumnTypeDateTime
    throw(ArgumentError("FlatGeobuf can't store values of type $T."))
end

geometrytype(::GeoInterface.PointTrait) = GeometryTypePoint
geometrytype(::GeoInterface.AbstractLineStringTrait) = GeometryTypeLineString
geometrytype(::GeoInterface.PolygonTrait) = GeometryTypePolygon
geometrytype(::GeoInterface.MultiPointTrait) = GeometryTypeMultiPoint
geometrytype(::GeoInterface.MultiLineStringTrait) = GeometryTypeMultiLineString
geometrytype(::GeoInterface.MultiPolygonTrait) = GeometryTypeMultiPolygon
geometrytype(::GeoInterface.GeometryCollectionTrait) = GeometryTypeGeometryCollection
geometrytype(trait) = throw(ArgumentError("FlatGeobuf.write can't write geometries with trait $trait."))

_crs(::Nothing) = Crs()
_crs(crs::GeoFormatTypes.EPSG{1}) = Crs(org="EPSG", code=Int32(only(GeoFormatTypes.val(crs))))
_crs(crs::GeoFormatTypes.AbstractWellKnownText) = Crs(wkt=GeoFormatTypes.val(crs))
function _crs(crs::GeoFormatTypes.GeoFormat)
    wkt = try
        convert(GeoFormatTypes.WellKnownText2, crs)
    catch e
        # GeoFormatTypes has no conversion unless Proj or ArchGDAL is loaded
        (e isa MethodError && e.f === convert) || rethrow()
        throw(ArgumentError("Can't convert a $(typeof(crs)) crs to WKT; load Proj or ArchGDAL, or pass an EPSG or WKT crs."))
    end
    _crs(wkt)
end

# The coordinates of one geometry, or of one part of a collection, reused for all of them
struct Coordinates
    ends::Vector{UInt32}
    xy::Vector{Float64}
    z::Vector{Float64}
    m::Vector{Float64}
end
Coordinates() = Coordinates(UInt32[], Float64[], Float64[], Float64[])

function _addpoint!(c::Coordinates, p, z::Bool, m::Bool)
    push!(c.xy, GeoInterface.x(p), GeoInterface.y(p))
    z && push!(c.z, GeoInterface.z(p))
    m && push!(c.m, GeoInterface.m(p))
end

_coordinates!(c, ::GeoInterface.PointTrait, geom, z, m) = _addpoint!(c, geom, z, m)
function _coordinates!(c, ::Union{GeoInterface.AbstractLineStringTrait,GeoInterface.MultiPointTrait}, geom, z, m)
    for p in GeoInterface.getpoint(geom)
        _addpoint!(c, p, z, m)
    end
end
function _coordinates!(c, ::Union{GeoInterface.PolygonTrait,GeoInterface.MultiLineStringTrait}, geom, z, m)
    for ring in GeoInterface.getgeom(geom)
        _coordinates!(c, GeoInterface.LineStringTrait(), ring, z, m)
        push!(c.ends, UInt32(length(c.xy) ÷ 2))
    end
end

# FlatGeobuf geometries already store their coordinates like this
function _coordinates!(c, geom::Geometry, z, m)
    append!(c.ends, geom.ends)
    append!(c.xy, geom.xy)
    z && append!(c.z, geom.z)
    m && append!(c.m, geom.m)
end

# Clear `b` for the next feature, like the Clear of flatbuffers' Builder, so its buffer is reused
function reset!(b::FlatBuffers.Builder)
    b.head = length(b.bytes)
    b.minalign = 1
    empty!(b.vtables)
    b.nested = b.finished = false
    b
end

# Copy a vector of numbers into the builder at once, as FlatBuffers.createbytevector does for bytes,
# instead of one number at a time as FlatBuffers.build! does
function vector!(b::FlatBuffers.Builder, v::Vector{T}) where {T<:Number}
    nbytes = length(v) * sizeof(T)
    FlatBuffers.startvector(b, sizeof(T), length(v), sizeof(T))
    b.head -= nbytes
    copyto!(b.bytes, b.head + 1, reinterpret(UInt8, v), 1, nbytes)
    FlatBuffers.endvector(b, length(v))
end

# Build the Geometry table of `geom` in `b`, with the slots of src/schema/feature.fbs, and return its offset.
# The parts of a collection are built before it, so they can all use `c`.
function geometry!(b::FlatBuffers.Builder, c::Coordinates, geom, z::Bool, m::Bool)
    trait = GeoInterface.geomtrait(geom)
    ends = xy = zs = ms = parts = 0
    if trait isa Union{GeoInterface.MultiPolygonTrait,GeoInterface.GeometryCollectionTrait}
        offsets = [geometry!(b, c, part, z, m) for part in GeoInterface.getgeom(geom)]
        parts = FlatBuffers.putoffsetvector!(b, offsets, length(offsets))
    else
        foreach(empty!, (c.ends, c.xy, c.z, c.m))
        geom isa Geometry ? _coordinates!(c, geom, z, m) : _coordinates!(c, trait, geom, z, m)
        isempty(c.ends) || (ends = vector!(b, c.ends))
        xy = vector!(b, c.xy)
        z && (zs = vector!(b, c.z))
        m && (ms = vector!(b, c.m))
    end
    FlatBuffers.startobject(b, 8)
    FlatBuffers.prependoffsetslot!(b, 1, ends, 0)
    FlatBuffers.prependoffsetslot!(b, 2, xy, 0)
    FlatBuffers.prependoffsetslot!(b, 3, zs, 0)
    FlatBuffers.prependoffsetslot!(b, 4, ms, 0)
    FlatBuffers.prependoffsetslot!(b, 8, parts, 0)
    FlatBuffers.prependslot!(b, 7, UInt8(geometrytype(trait)), 0x00)
    FlatBuffers.endobject(b)
end

# Encode the values of row `i`, recursing over the columns so each has its own element type
encode_properties(io::IO, columns::Tuple, i::Int, key::Int=0) = nothing
function encode_properties(io::IO, columns::Tuple{AbstractVector,Vararg}, i::Int, key::Int=0)
    value = first(columns)[i]
    if !ismissing(value)
        Base.write(io, UInt16(key))
        _encode(io, value)
    end
    encode_properties(io, Base.tail(columns), i, key + 1)
end
_encode(io::IO, x::Number) = Base.write(io, x)
_encode(io::IO, x::Union{Dates.Date,Dates.DateTime}) = _encode(io, string(x))  # ISO 8601
_encode(io::IO, x::String) = Base.write(io, UInt32(sizeof(x)), x)
_encode(io::IO, x::AbstractString) = _encode(io, String(x))  # e.g. InlineStrings would write their raw bytes

# Finish `b` with `root` and write it with its size prefix. Like the FinishSizePrefixed of flatbuffers,
# as used by GDAL, first pad so that the data is 8-byte aligned in the file (FlatGeobuf 3.0.1):
# https://github.com/OSGeo/gdal/blob/739fcf03bfcc075e300dbd45743187b380a17cdc/ogr/ogrsf_frmts/flatgeobuf/ogrflatgeobuflayer.cpp#L2332
# https://github.com/OSGeo/gdal/blob/739fcf03bfcc075e300dbd45743187b380a17cdc/third_party/flatbuffers/flatbuffer_builder.h#L1114-L1129
function write_sizeprefixed(io::IO, b::FlatBuffers.Builder, root)
    FlatBuffers.prep!(b, 8, 2 * sizeof(UInt32))
    FlatBuffers.prependoffset!(b, root)
    prepend!(b, UInt32(FlatBuffers.offset(b)))
    GC.@preserve b Base.write(io, FlatBuffers.bytes(b))  # bytes doesn't keep `b` alive
end

# Write the Feature table of `geom`, with the already encoded `properties`, using builder `b`
function write_feature(io::IO, b::FlatBuffers.Builder, c::Coordinates, geom, z::Bool, m::Bool, properties::Vector{UInt8})
    reset!(b)
    geometry = geometry!(b, c, geom, z, m)
    props = isempty(properties) ? 0 : FlatBuffers.createbytevector(b, properties)
    FlatBuffers.startobject(b, 3)
    FlatBuffers.prependoffsetslot!(b, 1, geometry, 0)
    FlatBuffers.prependoffsetslot!(b, 2, props, 0)
    write_sizeprefixed(io, b, FlatBuffers.endobject(b))
end

"""
    write(fn::AbstractString, table; geometrycolumn, crs, name)
    write(io::IO, table; geometrycolumn, crs, name)

Write a Tables.jl compatible `table` with GeoInterface compatible geometries as FlatGeobuf to `fn` or `io`,
and return `fn` or `io`.

FlatGeobuf stores a single geometry column. The header geometry type is set to `Unknown` if the
geometries have different types. Columns can hold numbers, `Bool`, strings, `Date` and `DateTime`
(stored as ISO 8601 text), and `missing`. A FlatGeobuffer keeps its column types. Missing geometries
are not supported, and no spatial index is written.

# Keywords
- `geometrycolumn`: name of the geometry column (or a tuple with one name), defaults to `first(GeoInterface.geometrycolumns(table))`.
- `crs`: a GeoFormatTypes coordinate reference system, defaults to `GeoInterface.crs(table)`.
- `name`: dataset name, defaults to the file name without extension.
"""
function write(fn::AbstractString, table; name::AbstractString=first(splitext(basename(fn))), kwargs...)
    # Read and check the table before opening `fn`, which may be the file being read
    header, geoms, values = prepare(table; name, kwargs...)
    open(fn, "w") do io
        write_features(io, header, geoms, values)
    end
    fn
end
write(io::IO, table; kwargs...) = write_features(io, prepare(table; kwargs...)...)

function prepare(table; geometrycolumn=first(GeoInterface.geometrycolumns(table)), crs=GeoInterface.crs(table), name::AbstractString="")
    cols = Tables.columns(table)
    sch = Tables.schema(cols)
    geometrycolumn = Symbol(geometrycolumn isa Union{Tuple,AbstractVector} ? only(geometrycolumn) : geometrycolumn)
    geometrycolumn in sch.names || throw(ArgumentError("Geometry column $geometrycolumn not found in table."))
    geoms = Tables.getcolumn(cols, geometrycolumn)
    geometry_type, z, m = geometryinfo(geoms)

    names = filter(!=(geometrycolumn), collect(sch.names))
    length(names) <= typemax(UInt16) + 1 || throw(ArgumentError("FlatGeobuf supports at most 65536 columns."))
    # Keep the column types of a FlatGeobuffer, which reads DateTime, Json and Binary columns as String
    columns = table isa FlatGeobuffer ? table.header.columns : map(names) do name
        T = Tables.columntype(sch, name)
        Column(name=String(name), type=columntype(T), nullable=Missing <: T)
    end
    values = Tuple(Tables.getcolumn(cols, name) for name in names)
    header = Header(
        name=name,
        geometry_type=geometry_type,
        has_z=z,
        has_m=m,
        columns=columns,
        features_count=UInt64(length(geoms)),
        index_node_size=UInt16(0),
        crs=_crs(crs),
    )
    header, geoms, values
end

# The header geometry type, which is Unknown for mixed types, and the Z and M flags,
# which apply to all features, in one pass over the geometries
function geometryinfo(geoms)
    type = dims = nothing
    for geom in geoms
        ismissing(geom) && throw(ArgumentError("FlatGeobuf.write doesn't support missing geometries."))
        t = geometrytype(GeoInterface.geomtrait(geom))
        type = isnothing(type) || type == t ? t : GeometryTypeUnknown
        d = (GeoInterface.is3d(geom), GeoInterface.ismeasured(geom))
        isnothing(dims) || d == dims || throw(ArgumentError("FlatGeobuf.write can't mix geometries with and without Z or M values."))
        dims = d
    end
    something(type, GeometryTypeUnknown), something(dims, (false, false))...
end

function write_features(io::IO, header::Header, geoms, values::Tuple)
    Base.write(io, MAGIC_BYTES)
    hb = FlatBuffers.Builder(Header)
    write_sizeprefixed(io, hb, FlatBuffers.buildbuffer!(hb, header))
    b = FlatBuffers.Builder(Feature, 1024)
    c = Coordinates()
    buf = IOBuffer()
    for (i, geom) in enumerate(geoms)
        encode_properties(buf, values, i)
        write_feature(io, b, c, geom, header.has_z, header.has_m, take!(buf))
    end
    io
end
