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

# Append the coordinates of a point to `g`
function _addpoint!(g::Geometry, p, z::Bool, m::Bool)
    push!(g.xy, GeoInterface.x(p), GeoInterface.y(p))
    z && push!(g.z, GeoInterface.z(p))
    m && push!(g.m, GeoInterface.m(p))
end

_geometry!(g, ::GeoInterface.PointTrait, geom, z, m) = _addpoint!(g, geom, z, m)
function _geometry!(g, ::Union{GeoInterface.AbstractLineStringTrait,GeoInterface.MultiPointTrait}, geom, z, m)
    for p in GeoInterface.getpoint(geom)
        _addpoint!(g, p, z, m)
    end
end
function _geometry!(g, ::Union{GeoInterface.PolygonTrait,GeoInterface.MultiLineStringTrait}, geom, z, m)
    for ring in GeoInterface.getgeom(geom)
        _geometry!(g, GeoInterface.LineStringTrait(), ring, z, m)
        push!(g.ends, UInt32(length(g.xy) ÷ 2))
    end
end
function _geometry!(g, ::Union{GeoInterface.MultiPolygonTrait,GeoInterface.GeometryCollectionTrait}, geom, z, m)
    for part in GeoInterface.getgeom(geom)
        push!(g.parts, convert_geometry(part, z, m))
    end
end

"""
    convert_geometry(geom, z=GeoInterface.is3d(geom), m=GeoInterface.ismeasured(geom)) -> Geometry

Convert a GeoInterface compatible geometry to a FlatGeobuf `Geometry`, storing Z and M values if `z` and `m` are set.
"""
function convert_geometry(geom, z::Bool=GeoInterface.is3d(geom), m::Bool=GeoInterface.ismeasured(geom))
    trait = GeoInterface.geomtrait(geom)
    g = Geometry(type=geometrytype(trait))
    _geometry!(g, trait, geom, z, m)
    g
end

function encode_properties(io::IO, columns, i)
    for (key, column) in enumerate(columns)
        value = column[i]
        ismissing(value) && continue
        Base.write(io, UInt16(key - 1))
        _encode(io, value)
    end
end
_encode(io::IO, x::Number) = Base.write(io, x)
_encode(io::IO, x::Union{Dates.Date,Dates.DateTime}) = _encode(io, string(x))  # ISO 8601
function _encode(io::IO, x::AbstractString)
    s = String(x)  # e.g. InlineStrings would otherwise write their raw bytes
    Base.write(io, UInt32(sizeof(s)), s)
end

# Write a FlatBuffer table with its UInt32 size prefix. Like GDAL, pad after the root offset so
# that the data is 8-byte aligned relative to the size prefix, as verified by e.g. the Rust reader.
function write_sizeprefixed(io::IO, x)
    b = FlatBuffers.build!(x)
    bytes = view(b.bytes, b.head+1:length(b.bytes))  # FlatBuffers.bytes(b) doesn't keep `b` alive
    pad = mod(-(4 + length(bytes)), 8)
    root = reinterpret(UInt32, bytes[1:4])[1] + UInt32(pad)  # offsets are relative, so only the root moves
    Base.write(io, UInt32(length(bytes) + pad), root, zeros(UInt8, pad), view(bytes, 5:length(bytes)))
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
    open(io -> write_features(io, header, geoms, values), fn, "w")
    fn
end
write(io::IO, table; kwargs...) = write_features(io, prepare(table; kwargs...)...)

function prepare(table; geometrycolumn=first(GeoInterface.geometrycolumns(table)), crs=GeoInterface.crs(table), name::AbstractString="")
    cols = Tables.columns(table)
    sch = Tables.schema(cols)
    geometrycolumn = Symbol(geometrycolumn isa Union{Tuple,AbstractVector} ? only(geometrycolumn) : geometrycolumn)
    geometrycolumn in sch.names || throw(ArgumentError("Geometry column $geometrycolumn not found in table."))
    geoms = Tables.getcolumn(cols, geometrycolumn)
    any(ismissing, geoms) && throw(ArgumentError("FlatGeobuf.write doesn't support missing geometries."))

    names = filter(!=(geometrycolumn), collect(sch.names))
    length(names) <= typemax(UInt16) + 1 || throw(ArgumentError("FlatGeobuf supports at most 65536 columns."))
    # Keep the column types of a FlatGeobuffer, which reads DateTime, Json and Binary columns as String
    columns = table isa FlatGeobuffer ? table.header.columns : map(names) do name
        T = Tables.columntype(sch, name)
        Column(name=String(name), type=columntype(T), nullable=Missing <: T)
    end
    values = [Tables.getcolumn(cols, name) for name in names]

    types = unique(geometrytype(GeoInterface.geomtrait(geom)) for geom in geoms)
    # The header Z and M flags apply to all features
    z = any(GeoInterface.is3d, geoms)
    m = any(GeoInterface.ismeasured, geoms)
    all(g -> GeoInterface.is3d(g) == z && GeoInterface.ismeasured(g) == m, geoms) ||
        throw(ArgumentError("FlatGeobuf.write can't mix geometries with and without Z or M values."))
    header = Header(
        name=name,
        geometry_type=length(types) == 1 ? only(types) : GeometryTypeUnknown,
        has_z=z,
        has_m=m,
        columns=columns,
        features_count=UInt64(length(geoms)),
        index_node_size=UInt16(0),
        crs=_crs(crs),
    )
    header, geoms, values
end

function write_features(io::IO, header::Header, geoms, values)
    Base.write(io, MAGIC_BYTES)
    write_sizeprefixed(io, header)
    buf = IOBuffer()
    for (i, geom) in enumerate(geoms)
        encode_properties(buf, values, i)
        feature = Feature(geometry=convert_geometry(geom, header.has_z, header.has_m), properties=take!(buf))
        write_sizeprefixed(io, feature)
    end
    io
end
