
# Magic bytes for FlatGeobuf format
const MAGIC_BYTES = UInt8[0x66, 0x67, 0x62, 0x03, 0x66, 0x67, 0x62, 0x00]

# Reverse lookup: Julia type -> ColumnType
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
    String => ColumnTypeString,
)

# GeoInterface trait -> FlatGeobuf GeometryType
const trait_to_geomtype = Dict(
    GeoInterface.PointTrait() => GeometryTypePoint,
    GeoInterface.LineStringTrait() => GeometryTypeLineString,
    GeoInterface.PolygonTrait() => GeometryTypePolygon,
    GeoInterface.MultiPointTrait() => GeometryTypeMultiPoint,
    GeoInterface.MultiLineStringTrait() => GeometryTypeMultiLineString,
    GeoInterface.MultiPolygonTrait() => GeometryTypeMultiPolygon,
    GeoInterface.GeometryCollectionTrait() => GeometryTypeGeometryCollection,
)

# Convert GeoFormatTypes CRS wrappers to FlatGeobuf Crs
Base.convert(::Type{Crs}, ::Nothing) = Crs()
Base.convert(::Type{Crs}, crs::Crs) = crs
Base.convert(::Type{Crs}, crs::GeoFormatTypes.EPSG) = Crs(org="EPSG", code=Int32(GeoFormatTypes.val(crs)))
Base.convert(::Type{Crs}, crs::GeoFormatTypes.AbstractWellKnownText) = Crs(wkt=string(GeoFormatTypes.val(crs)))

"""
    write_magic(io::IO)

Write the 8-byte FlatGeobuf magic header.
"""
function write_magic(io::IO)
    Base.write(io, MAGIC_BYTES)
end

"""
    write_header(io::IO, header::Header)

Write a size-prefixed Header FlatBuffer to the IO stream.
"""
function write_header(io::IO, header::Header)
    # Serialize header to bytes
    buf = IOBuffer()
    FlatBuffers.serialize(buf, header)
    header_bytes = take!(buf)

    # Write size prefix (UInt32) then header bytes
    Base.write(io, UInt32(length(header_bytes)))
    Base.write(io, header_bytes)
end

"""
    encode_properties(props::NamedTuple, columns::Vector{Column})

Encode properties to the FlatGeobuf binary property format.
"""
function encode_properties(props::NamedTuple, columns::Vector{Column})
    buf = IOBuffer()
    for (i, col) in enumerate(columns)
        name = Symbol(col.name)
        haskey(props, name) || continue
        val = getproperty(props, name)
        ismissing(val) && continue  # Skip missing values

        Base.write(buf, UInt16(i - 1))  # 0-indexed column index

        T = lookup[col.type]
        if T == String
            bytes = Vector{UInt8}(val)
            Base.write(buf, UInt32(length(bytes)))
            Base.write(buf, bytes)
        else
            Base.write(buf, T(val))  # Fixed-size numeric
        end
    end
    take!(buf)
end

"""
    encode_properties(feature::Feature)

Encode properties from an existing Feature.
"""
function encode_properties(feature::Feature)
    props = split_properties(feature.properties, feature.columns)
    encode_properties(props, feature.columns)
end

"""
    write_feature(io::IO, feature::Feature)

Write a size-prefixed Feature FlatBuffer to the IO stream.
"""
function write_feature(io::IO, feature::Feature)
    # Serialize feature to bytes
    buf = IOBuffer()
    FlatBuffers.serialize(buf, feature)
    feature_bytes = take!(buf)

    # Write size prefix (UInt32) then feature bytes
    Base.write(io, UInt32(length(feature_bytes)))
    Base.write(io, feature_bytes)
end

"""
    write(filename::AbstractString, fgb::FlatGeobuffer)

Write a FlatGeobuffer to a file.
"""
function write(filename::AbstractString, fgb::FlatGeobuffer)
    open(filename, "w") do io
        write(io, fgb)
    end
    filename
end

"""
    write(io::IO, fgb::FlatGeobuffer)

Write a FlatGeobuffer to an IO stream.
"""
function write(io::IO, fgb::FlatGeobuffer)
    # Write magic bytes
    write_magic(io)

    # Prepare header - update feature count and disable index
    header = fgb.header
    header.index_node_size = UInt16(0)  # No index for now

    # Write header
    write_header(io, header)

    # Write all features
    for feature in fgb
        write_feature(io, feature)
    end

    nothing
end

# =============================================================================
# GeoInterface geometry conversion
# =============================================================================

"""
    convert_geometry(geom) -> Geometry

Convert any GeoInterface-compatible geometry to a FlatGeobuf Geometry.
"""
function convert_geometry(geom)
    trait = GeoInterface.geomtrait(geom)
    convert_geometry(trait, geom)
end

# Point
function convert_geometry(::GeoInterface.PointTrait, geom)
    ncoord = GeoInterface.ncoord(geom)
    xy = Float64[GeoInterface.getcoord(geom, 1), GeoInterface.getcoord(geom, 2)]
    z = ncoord >= 3 ? Float64[GeoInterface.getcoord(geom, 3)] : Float64[]
    m = ncoord >= 4 ? Float64[GeoInterface.getcoord(geom, 4)] : Float64[]
    Geometry(ends=UInt32[], xy=xy, z=z, m=m, t=Float64[], tm=UInt64[], type=GeometryTypePoint, parts=Geometry[])
end

# LineString
function convert_geometry(::GeoInterface.LineStringTrait, geom)
    npts = GeoInterface.ngeom(geom)
    xy = Float64[]
    z = Float64[]
    m = Float64[]
    has_z = false
    has_m = false

    for i in 1:npts
        pt = GeoInterface.getgeom(geom, i)
        ncoord = GeoInterface.ncoord(pt)
        push!(xy, GeoInterface.getcoord(pt, 1))
        push!(xy, GeoInterface.getcoord(pt, 2))
        if ncoord >= 3
            has_z = true
            push!(z, GeoInterface.getcoord(pt, 3))
        end
        if ncoord >= 4
            has_m = true
            push!(m, GeoInterface.getcoord(pt, 4))
        end
    end

    Geometry(ends=UInt32[], xy=xy, z=has_z ? z : Float64[], m=has_m ? m : Float64[],
             t=Float64[], tm=UInt64[], type=GeometryTypeLineString, parts=Geometry[])
end

# Polygon
function convert_geometry(::GeoInterface.PolygonTrait, geom)
    nrings = GeoInterface.ngeom(geom)
    xy = Float64[]
    z = Float64[]
    m = Float64[]
    ends = UInt32[]
    has_z = false
    has_m = false
    coord_count = 0

    for i in 1:nrings
        ring = GeoInterface.getgeom(geom, i)
        npts = GeoInterface.ngeom(ring)
        for j in 1:npts
            pt = GeoInterface.getgeom(ring, j)
            ncoord = GeoInterface.ncoord(pt)
            push!(xy, GeoInterface.getcoord(pt, 1))
            push!(xy, GeoInterface.getcoord(pt, 2))
            if ncoord >= 3
                has_z = true
                push!(z, GeoInterface.getcoord(pt, 3))
            end
            if ncoord >= 4
                has_m = true
                push!(m, GeoInterface.getcoord(pt, 4))
            end
            coord_count += 1
        end
        push!(ends, UInt32(coord_count))
    end

    Geometry(ends=ends, xy=xy, z=has_z ? z : Float64[], m=has_m ? m : Float64[],
             t=Float64[], tm=UInt64[], type=GeometryTypePolygon, parts=Geometry[])
end

# MultiPoint
function convert_geometry(::GeoInterface.MultiPointTrait, geom)
    npts = GeoInterface.ngeom(geom)
    xy = Float64[]
    z = Float64[]
    m = Float64[]
    has_z = false
    has_m = false

    for i in 1:npts
        pt = GeoInterface.getgeom(geom, i)
        ncoord = GeoInterface.ncoord(pt)
        push!(xy, GeoInterface.getcoord(pt, 1))
        push!(xy, GeoInterface.getcoord(pt, 2))
        if ncoord >= 3
            has_z = true
            push!(z, GeoInterface.getcoord(pt, 3))
        end
        if ncoord >= 4
            has_m = true
            push!(m, GeoInterface.getcoord(pt, 4))
        end
    end

    Geometry(ends=UInt32[], xy=xy, z=has_z ? z : Float64[], m=has_m ? m : Float64[],
             t=Float64[], tm=UInt64[], type=GeometryTypeMultiPoint, parts=Geometry[])
end

# MultiLineString
function convert_geometry(::GeoInterface.MultiLineStringTrait, geom)
    nlines = GeoInterface.ngeom(geom)
    xy = Float64[]
    z = Float64[]
    m = Float64[]
    ends = UInt32[]
    has_z = false
    has_m = false
    coord_count = 0

    for i in 1:nlines
        line = GeoInterface.getgeom(geom, i)
        npts = GeoInterface.ngeom(line)
        for j in 1:npts
            pt = GeoInterface.getgeom(line, j)
            ncoord = GeoInterface.ncoord(pt)
            push!(xy, GeoInterface.getcoord(pt, 1))
            push!(xy, GeoInterface.getcoord(pt, 2))
            if ncoord >= 3
                has_z = true
                push!(z, GeoInterface.getcoord(pt, 3))
            end
            if ncoord >= 4
                has_m = true
                push!(m, GeoInterface.getcoord(pt, 4))
            end
            coord_count += 1
        end
        push!(ends, UInt32(coord_count))
    end

    Geometry(ends=ends, xy=xy, z=has_z ? z : Float64[], m=has_m ? m : Float64[],
             t=Float64[], tm=UInt64[], type=GeometryTypeMultiLineString, parts=Geometry[])
end

# MultiPolygon - uses parts for nested structure
function convert_geometry(::GeoInterface.MultiPolygonTrait, geom)
    npolys = GeoInterface.ngeom(geom)
    parts = Geometry[]

    for i in 1:npolys
        poly = GeoInterface.getgeom(geom, i)
        push!(parts, convert_geometry(GeoInterface.PolygonTrait(), poly))
    end

    Geometry(ends=UInt32[], xy=Float64[], z=Float64[], m=Float64[],
             t=Float64[], tm=UInt64[], type=GeometryTypeMultiPolygon, parts=parts)
end

# GeometryCollection
function convert_geometry(::GeoInterface.GeometryCollectionTrait, geom)
    ngeoms = GeoInterface.ngeom(geom)
    parts = Geometry[]

    for i in 1:ngeoms
        subgeom = GeoInterface.getgeom(geom, i)
        push!(parts, convert_geometry(subgeom))
    end

    Geometry(ends=UInt32[], xy=Float64[], z=Float64[], m=Float64[],
             t=Float64[], tm=UInt64[], type=GeometryTypeGeometryCollection, parts=parts)
end

# =============================================================================
# Tables.jl write support
# =============================================================================

"""
    julia_type_to_columntype(T::Type)

Convert a Julia type to a FlatGeobuf ColumnType.
"""
function julia_type_to_columntype(T::Type)
    # Handle Union{Missing, T}
    if T isa Union
        T = Base.nonmissingtype(T)
    end
    get(reverse_lookup, T, ColumnTypeString)  # Default to String
end

"""
    infer_columns(table, geom_column::Symbol)

Infer FlatGeobuf columns from a Tables.jl-compatible table.
Returns (columns, geometry_column_name).
"""
function infer_columns(table, geom_column::Symbol)
    sch = Tables.schema(table)
    columns = Column[]

    for (name, T) in zip(sch.names, sch.types)
        name == geom_column && continue  # Skip geometry column
        col_type = julia_type_to_columntype(T)
        nullable = T isa Union && Missing <: T
        push!(columns, Column(name=string(name), type=col_type, nullable=nullable))
    end

    columns
end

"""
    detect_geometry_type(table, geom_column::Symbol)

Detect the geometry type from the first feature in the table.
"""
function detect_geometry_type(table, geom_column::Symbol)
    for row in Tables.rows(table)
        geom = Tables.getcolumn(row, geom_column)
        trait = GeoInterface.geomtrait(geom)
        return get(trait_to_geomtype, trait, GeometryTypeUnknown)
    end
    GeometryTypeUnknown
end

"""
    write(filename::AbstractString, table; geometrycolumn=first(GeoInterface.geometrycolumns(table)), crs=GeoInterface.crs(table), name::AbstractString="")

Write a Tables.jl-compatible table to a FlatGeobuf file.

The table must have a geometry column containing GeoInterface-compatible geometries.

# Arguments
- `geometrycolumn`: Name of the geometry column. Defaults to `first(GeoInterface.geometrycolumns(table))`.
- `crs`: Coordinate reference system. Defaults to `GeoInterface.crs(table)`.
- `name`: Dataset name for the header.
"""
function write(filename::AbstractString, table; geometrycolumn=first(GeoInterface.geometrycolumns(table)), crs=GeoInterface.crs(table), name::AbstractString="")
    open(filename, "w") do io
        write(io, table; geometrycolumn=geometrycolumn, crs=crs, name=name)
    end
    filename
end

"""
    write(io::IO, table; geometrycolumn=first(GeoInterface.geometrycolumns(table)), crs=GeoInterface.crs(table), name::AbstractString="")

Write a Tables.jl-compatible table to an IO stream in FlatGeobuf format.
"""
function write(io::IO, table; geometrycolumn=first(GeoInterface.geometrycolumns(table)), crs=GeoInterface.crs(table), name::AbstractString="")
    geom_column = geometrycolumn

    rows = Tables.rows(table)

    # Collect rows to get count and detect geometry type
    collected_rows = collect(rows)
    features_count = length(collected_rows)

    # Infer schema
    columns = infer_columns(table, geom_column)
    geometry_type = detect_geometry_type(table, geom_column)

    # Detect coordinate dimensions from first geometry
    has_z = false
    has_m = false
    if features_count > 0
        first_geom = Tables.getcolumn(collected_rows[1], geom_column)
        ncoord = GeoInterface.ncoord(first_geom)
        has_z = ncoord >= 3
        has_m = ncoord >= 4
    end

    # Build header
    header = Header(
        name=name,
        geometry_type=geometry_type,
        has_z=has_z,
        has_m=has_m,
        columns=columns,
        features_count=UInt64(features_count),
        index_node_size=UInt16(0),  # No index
        crs=convert(Crs, crs)
    )

    # Write magic and header
    write_magic(io)
    write_header(io, header)

    # Write features
    col_names = Tuple(Symbol(col.name) for col in columns)
    for row in collected_rows
        geom = Tables.getcolumn(row, geom_column)
        fgb_geom = convert_geometry(geom)

        # Build properties as NamedTuple
        prop_values = [Tables.getcolumn(row, name) for name in col_names]
        props = NamedTuple{col_names}(Tuple(prop_values))
        props_bytes = encode_properties(props, columns)

        # Create and write feature
        feature = Feature(geometry=fgb_geom, properties=props_bytes, columns=Column[])
        write_feature(io, feature)
    end

    nothing
end
