
@enum ColumnType::UInt8 begin
    ColumnTypeByte = 0
    ColumnTypeUByte = 1
    ColumnTypeBool = 2
    ColumnTypeShort = 3
    ColumnTypeUShort = 4
    ColumnTypeInt = 5
    ColumnTypeUInt = 6
    ColumnTypeLong = 7
    ColumnTypeULong = 8
    ColumnTypeFloat = 9
    ColumnTypeDouble = 10
    ColumnTypeString = 11
    ColumnTypeJson = 12
    ColumnTypeDateTime = 13
    ColumnTypeBinary = 14
end

FlatBuffers.@with_kw mutable struct Column
    name::String = ""
    type::ColumnType = 0
    title::String = ""
    description::String = ""
    width::Int32 = -1
    precision::Int32 = -1
    scale::Int32 = -1
    nullable::Bool = true
    unique::Bool = false
    primary_key::Bool = false
    metadata::String = ""
end
FlatBuffers.@ALIGN(Column, 1)
FlatBuffers.slot_offsets(::Type{T}) where {T <: Column} = [
    0x00000004, 0x00000006, 0x00000008, 0x0000000A,
    0x0000000C, 0x0000000E, 0x00000010, 0x00000012,
    0x00000014, 0x00000016, 0x00000018
]

Column(buf::AbstractVector{UInt8}) = FlatBuffers.read(Column, buf)
Column(io::IO) = FlatBuffers.deserialize(io, Column)

@enum GeometryType::UInt8 begin
    GeometryTypeUnknown = 0
    GeometryTypePoint = 1
    GeometryTypeLineString = 2
    GeometryTypePolygon = 3
    GeometryTypeMultiPoint = 4
    GeometryTypeMultiLineString = 5
    GeometryTypeMultiPolygon = 6
    GeometryTypeGeometryCollection = 7
    GeometryTypeCircularString = 8
    GeometryTypeCompoundCurve = 9
    GeometryTypeCurvePolygon = 10
    GeometryTypeMultiCurve = 11
    GeometryTypeMultiSurface = 12
    GeometryTypeCurve = 13
    GeometryTypeSurface = 14
    GeometryTypePolyhedralSurface = 15
    GeometryTypeTIN = 16
    GeometryTypeTriangle = 17
end

FlatBuffers.@with_kw mutable struct Crs
    org::String = ""
    code::Int32 = 0
    name::String = ""
    description::String = ""
    wkt::String = ""
    code_string::String = ""
end
FlatBuffers.@ALIGN(Crs, 1)
FlatBuffers.slot_offsets(::Type{T}) where {T <: Crs} = [
    0x00000004, 0x00000006, 0x00000008, 0x0000000A,
    0x0000000C, 0x0000000E
]

Crs(buf::AbstractVector{UInt8}) = FlatBuffers.read(Crs, buf)
Crs(io::IO) = FlatBuffers.deserialize(io, Crs)


FlatBuffers.@with_kw mutable struct Header
    name::String = ""
    envelope::Vector{Float64} = []
    geometry_type::GeometryType = 0
    hasZ::Bool = false
    hasM::Bool = false
    hasT::Bool = false
    hasTM::Bool = false
    columns::Vector{Column} = []
    features_count::UInt64 = 0
    index_node_size::UInt16 = 16
    crs::Crs = Crs()
    title::String = ""
    description::String = ""
    metadata::String = ""
end
FlatBuffers.@ALIGN(Header, 1)
FlatBuffers.slot_offsets(::Type{T}) where {T <: Header} = [
    0x00000004, 0x00000006, 0x00000008, 0x0000000A,
    0x0000000C, 0x0000000E, 0x00000010, 0x00000012,
    0x00000014, 0x00000016, 0x00000018, 0x0000001A,
    0x0000001C, 0x0000001E
]
FlatBuffers.root_type(::Type{T}) where {T <: Header} = true

Header(buf::AbstractVector{UInt8}) = FlatBuffers.read(Header, buf)
Header(io::IO) = FlatBuffers.deserialize(io, Header)
