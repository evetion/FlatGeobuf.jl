# Code generated by the FlatBuffers compiler. DO NOT EDIT.

module Gen

using FlatBuffers


FlatBuffers.@scopedenum GeometryType::UInt8 Unknown = 0 Point = 1 LineString = 2 Polygon = 3 MultiPoint = 4 MultiLineString = 5 MultiPolygon = 6 GeometryCollection = 7 CircularString = 8 CompoundCurve = 9 CurvePolygon = 10 MultiCurve = 11 MultiSurface = 12 Curve = 13 Surface = 14 PolyhedralSurface = 15 TIN = 16 Triangle = 17
FlatBuffers.@scopedenum ColumnType::UInt8 Byte = 0 UByte = 1 CBool = 2 Short = 3 UShort = 4 Int = 5 UInt = 6 Long = 7 ULong = 8 Float = 9 Double = 10 CString = 11 Json = 12 DateTime = 13 Binary = 14

struct Geometry <: FlatBuffers.Table
    bytes::Vector{UInt8}
    pos::Base.Int
end

Base.propertynames(::Geometry) = (
    :ends,
    :xy,
    :z,
    :m,
    :t,
    :tm,
    :type,
    :parts,
)

function Base.getproperty(x::Geometry, field::Symbol)
    if field === :ends
        #GetMemberOfVectorOfNonStruct
        o = FlatBuffers.offset(x, 4)
        o != 0 && return FlatBuffers.Array{UInt32}(x, o)
    elseif field === :xy
        #GetMemberOfVectorOfNonStruct
        o = FlatBuffers.offset(x, 6)
        o != 0 && return FlatBuffers.Array{Float64}(x, o)
    elseif field === :z
        #GetMemberOfVectorOfNonStruct
        o = FlatBuffers.offset(x, 8)
        o != 0 && return FlatBuffers.Array{Float64}(x, o)
    elseif field === :m
        #GetMemberOfVectorOfNonStruct
        o = FlatBuffers.offset(x, 10)
        o != 0 && return FlatBuffers.Array{Float64}(x, o)
    elseif field === :t
        #GetMemberOfVectorOfNonStruct
        o = FlatBuffers.offset(x, 12)
        o != 0 && return FlatBuffers.Array{Float64}(x, o)
    elseif field === :tm
        #GetMemberOfVectorOfNonStruct
        o = FlatBuffers.offset(x, 14)
        o != 0 && return FlatBuffers.Array{UInt64}(x, o)
    elseif field === :type
        #GetScalarFieldOfTable
        o = FlatBuffers.offset(x, 16)
        o != 0 && return FlatBuffers.get(x, o + FlatBuffers.pos(x), GeometryType)
        return GeometryType(0)
    elseif field === :parts
        #GetMemberOfVectorOfStruct
        o = FlatBuffers.offset(x, 18)
        o != 0 && return FlatBuffers.Array{Geometry}(x, o)
    end
    return nothing
end

module GeometryProperties
abstract type AbstractProperty end
struct ends <: AbstractProperty end
struct xy <: AbstractProperty end
struct z <: AbstractProperty end
struct m <: AbstractProperty end
struct t <: AbstractProperty end
struct tm <: AbstractProperty end
struct type <: AbstractProperty end
struct parts <: AbstractProperty end
end

function Base.getindex(x::Geometry, ::Type{GeometryProperties.ends})
    #GetMemberOfVectorOfNonStruct
    o = FlatBuffers.offset(x, 4)
    o != 0 && return FlatBuffers.Array{UInt32}(x, o)
    return nothing
end

function Base.getindex(x::Geometry, ::Type{GeometryProperties.xy})
    #GetMemberOfVectorOfNonStruct
    o = FlatBuffers.offset(x, 6)
    o != 0 && return FlatBuffers.Array{Float64}(x, o)
    return nothing
end

function Base.getindex(x::Geometry, ::Type{GeometryProperties.z})
    #GetMemberOfVectorOfNonStruct
    o = FlatBuffers.offset(x, 8)
    o != 0 && return FlatBuffers.Array{Float64}(x, o)
    return nothing
end

function Base.getindex(x::Geometry, ::Type{GeometryProperties.m})
    #GetMemberOfVectorOfNonStruct
    o = FlatBuffers.offset(x, 10)
    o != 0 && return FlatBuffers.Array{Float64}(x, o)
    return nothing
end

function Base.getindex(x::Geometry, ::Type{GeometryProperties.t})
    #GetMemberOfVectorOfNonStruct
    o = FlatBuffers.offset(x, 12)
    o != 0 && return FlatBuffers.Array{Float64}(x, o)
    return nothing
end

function Base.getindex(x::Geometry, ::Type{GeometryProperties.tm})
    #GetMemberOfVectorOfNonStruct
    o = FlatBuffers.offset(x, 14)
    o != 0 && return FlatBuffers.Array{UInt64}(x, o)
    return nothing
end

function Base.getindex(x::Geometry, ::Type{GeometryProperties.type})
    #GetScalarFieldOfTable
    o = FlatBuffers.offset(x, 16)
    o != 0 && return FlatBuffers.get(x, o + FlatBuffers.pos(x), GeometryType)
    return GeometryType(0)
end

function Base.getindex(x::Geometry, ::Type{GeometryProperties.parts})
    #GetMemberOfVectorOfStruct
    o = FlatBuffers.offset(x, 18)
    o != 0 && return FlatBuffers.Array{Geometry}(x, o)
    return nothing
end


GeometryStart(b::FlatBuffers.Builder) = FlatBuffers.startobject!(b, 8)
GeometryAddEnds(b::FlatBuffers.Builder, ends::FlatBuffers.UOffsetT) = FlatBuffers.prependoffsetslot!(b, 0, ends, 0)
GeometryStartEndsVector(b::FlatBuffers.Builder, numelems::Integer) = FlatBuffers.startvector!(b, 4, numelems, 4)
GeometryAddXy(b::FlatBuffers.Builder, xy::FlatBuffers.UOffsetT) = FlatBuffers.prependoffsetslot!(b, 1, xy, 0)
GeometryStartXyVector(b::FlatBuffers.Builder, numelems::Integer) = FlatBuffers.startvector!(b, 8, numelems, 8)
GeometryAddZ(b::FlatBuffers.Builder, z::FlatBuffers.UOffsetT) = FlatBuffers.prependoffsetslot!(b, 2, z, 0)
GeometryStartZVector(b::FlatBuffers.Builder, numelems::Integer) = FlatBuffers.startvector!(b, 8, numelems, 8)
GeometryAddM(b::FlatBuffers.Builder, m::FlatBuffers.UOffsetT) = FlatBuffers.prependoffsetslot!(b, 3, m, 0)
GeometryStartMVector(b::FlatBuffers.Builder, numelems::Integer) = FlatBuffers.startvector!(b, 8, numelems, 8)
GeometryAddT(b::FlatBuffers.Builder, t::FlatBuffers.UOffsetT) = FlatBuffers.prependoffsetslot!(b, 4, t, 0)
GeometryStartTVector(b::FlatBuffers.Builder, numelems::Integer) = FlatBuffers.startvector!(b, 8, numelems, 8)
GeometryAddTm(b::FlatBuffers.Builder, tm::FlatBuffers.UOffsetT) = FlatBuffers.prependoffsetslot!(b, 5, tm, 0)
GeometryStartTmVector(b::FlatBuffers.Builder, numelems::Integer) = FlatBuffers.startvector!(b, 8, numelems, 8)
GeometryAddType(b::FlatBuffers.Builder, type::GeometryType) = FlatBuffers.prependslot!(b, 6, type, 0)
GeometryAddParts(b::FlatBuffers.Builder, parts::FlatBuffers.UOffsetT) = FlatBuffers.prependoffsetslot!(b, 7, parts, 0)
GeometryStartPartsVector(b::FlatBuffers.Builder, numelems::Integer) = FlatBuffers.startvector!(b, 4, numelems, 4)
GeometryEnd(b::FlatBuffers.Builder) = FlatBuffers.endobject!(b)

struct Feature <: FlatBuffers.Table
    bytes::Vector{UInt8}
    pos::Base.Int
end

Base.propertynames(::Feature) = (
    :geometry,
    :properties,
    :columns,
)

function Base.getproperty(x::Feature, field::Symbol)
    if field === :geometry
        #GetStructFieldOfTable
        o = FlatBuffers.offset(x, 4)
        if o != 0
            y = FlatBuffers.indirect(x, o + FlatBuffers.pos(x))
            return FlatBuffers.init(Geometry, FlatBuffers.bytes(x), y)
        end
    elseif field === :properties
        #GetMemberOfVectorOfNonStruct
        o = FlatBuffers.offset(x, 6)
        o != 0 && return FlatBuffers.Array{UInt8}(x, o)
    elseif field === :columns
        #GetMemberOfVectorOfStruct
        o = FlatBuffers.offset(x, 8)
        o != 0 && return FlatBuffers.Array{Column}(x, o)
    end
    return nothing
end

module FeatureProperties
abstract type AbstractProperty end
struct geometry <: AbstractProperty end
struct properties <: AbstractProperty end
struct columns <: AbstractProperty end
end

function Base.getindex(x::Feature, ::Type{FeatureProperties.geometry})
    #GetStructFieldOfTable
    o = FlatBuffers.offset(x, 4)
    if o != 0
        y = FlatBuffers.indirect(x, o + FlatBuffers.pos(x))
        return FlatBuffers.init(Geometry, FlatBuffers.bytes(x), y)
    end
    return nothing
end

function Base.getindex(x::Feature, ::Type{FeatureProperties.properties})
    #GetMemberOfVectorOfNonStruct
    o = FlatBuffers.offset(x, 6)
    o != 0 && return FlatBuffers.Array{UInt8}(x, o)
    return nothing
end

function Base.getindex(x::Feature, ::Type{FeatureProperties.columns})
    #GetMemberOfVectorOfStruct
    o = FlatBuffers.offset(x, 8)
    o != 0 && return FlatBuffers.Array{Column}(x, o)
    return nothing
end


FeatureStart(b::FlatBuffers.Builder) = FlatBuffers.startobject!(b, 3)
FeatureAddGeometry(b::FlatBuffers.Builder, geometry::FlatBuffers.UOffsetT) = FlatBuffers.prependoffsetslot!(b, 0, geometry, 0)
FeatureAddProperties(b::FlatBuffers.Builder, properties::FlatBuffers.UOffsetT) = FlatBuffers.prependoffsetslot!(b, 1, properties, 0)
FeatureStartPropertiesVector(b::FlatBuffers.Builder, numelems::Integer) = FlatBuffers.startvector!(b, 1, numelems, 1)
FeatureAddColumns(b::FlatBuffers.Builder, columns::FlatBuffers.UOffsetT) = FlatBuffers.prependoffsetslot!(b, 2, columns, 0)
FeatureStartColumnsVector(b::FlatBuffers.Builder, numelems::Integer) = FlatBuffers.startvector!(b, 4, numelems, 4)
FeatureEnd(b::FlatBuffers.Builder) = FlatBuffers.endobject!(b)


struct Column <: FlatBuffers.Table
    bytes::Vector{UInt8}
    pos::Base.Int
end

Base.propertynames(::Column) = (
    :name,
    :type,
    :title,
    :description,
    :width,
    :precision,
    :scale,
    :nullable,
    :unique,
    :primaryKey,
    :metadata,
)

function Base.getproperty(x::Column, field::Symbol)
    if field === :name
        #GetStringField
        o = FlatBuffers.offset(x, 4)
        o != 0 && return String(x, o + FlatBuffers.pos(x))
        return string(0)
    elseif field === :type
        #GetScalarFieldOfTable
        o = FlatBuffers.offset(x, 6)
        o != 0 && return FlatBuffers.get(x, o + FlatBuffers.pos(x), ColumnType)
        return ColumnType(0)
    elseif field === :title
        #GetStringField
        o = FlatBuffers.offset(x, 8)
        o != 0 && return String(x, o + FlatBuffers.pos(x))
        return string(0)
    elseif field === :description
        #GetStringField
        o = FlatBuffers.offset(x, 10)
        o != 0 && return String(x, o + FlatBuffers.pos(x))
        return string(0)
    elseif field === :width
        #GetScalarFieldOfTable
        o = FlatBuffers.offset(x, 12)
        o != 0 && return FlatBuffers.get(x, o + FlatBuffers.pos(x), Int32)
        return Int32(-1)
    elseif field === :precision
        #GetScalarFieldOfTable
        o = FlatBuffers.offset(x, 14)
        o != 0 && return FlatBuffers.get(x, o + FlatBuffers.pos(x), Int32)
        return Int32(-1)
    elseif field === :scale
        #GetScalarFieldOfTable
        o = FlatBuffers.offset(x, 16)
        o != 0 && return FlatBuffers.get(x, o + FlatBuffers.pos(x), Int32)
        return Int32(-1)
    elseif field === :nullable
        #GetScalarFieldOfTable
        o = FlatBuffers.offset(x, 18)
        o != 0 && return FlatBuffers.get(x, o + FlatBuffers.pos(x), Bool)
        return Bool(true)
    elseif field === :unique
        #GetScalarFieldOfTable
        o = FlatBuffers.offset(x, 20)
        o != 0 && return FlatBuffers.get(x, o + FlatBuffers.pos(x), Bool)
        return Bool(false)
    elseif field === :primaryKey
        #GetScalarFieldOfTable
        o = FlatBuffers.offset(x, 22)
        o != 0 && return FlatBuffers.get(x, o + FlatBuffers.pos(x), Bool)
        return Bool(false)
    elseif field === :metadata
        #GetStringField
        o = FlatBuffers.offset(x, 24)
        o != 0 && return String(x, o + FlatBuffers.pos(x))
        return string(0)
    end
    return nothing
end

module ColumnProperties
abstract type AbstractProperty end
struct name <: AbstractProperty end
struct type <: AbstractProperty end
struct title <: AbstractProperty end
struct description <: AbstractProperty end
struct width <: AbstractProperty end
struct precision <: AbstractProperty end
struct scale <: AbstractProperty end
struct nullable <: AbstractProperty end
struct unique <: AbstractProperty end
struct primaryKey <: AbstractProperty end
struct metadata <: AbstractProperty end
end

function Base.getindex(x::Column, ::Type{ColumnProperties.name})
    #GetStringField
    o = FlatBuffers.offset(x, 4)
    o != 0 && return String(x, o + FlatBuffers.pos(x))
    return string(0)
    return nothing
end

function Base.getindex(x::Column, ::Type{ColumnProperties.type})
    #GetScalarFieldOfTable
    o = FlatBuffers.offset(x, 6)
    o != 0 && return FlatBuffers.get(x, o + FlatBuffers.pos(x), ColumnType)
    return ColumnType(0)
end

function Base.getindex(x::Column, ::Type{ColumnProperties.title})
    #GetStringField
    o = FlatBuffers.offset(x, 8)
    o != 0 && return String(x, o + FlatBuffers.pos(x))
    return string(0)
    return nothing
end

function Base.getindex(x::Column, ::Type{ColumnProperties.description})
    #GetStringField
    o = FlatBuffers.offset(x, 10)
    o != 0 && return String(x, o + FlatBuffers.pos(x))
    return string(0)
    return nothing
end

function Base.getindex(x::Column, ::Type{ColumnProperties.width})
    #GetScalarFieldOfTable
    o = FlatBuffers.offset(x, 12)
    o != 0 && return FlatBuffers.get(x, o + FlatBuffers.pos(x), Int32)
    return Int32(-1)
end

function Base.getindex(x::Column, ::Type{ColumnProperties.precision})
    #GetScalarFieldOfTable
    o = FlatBuffers.offset(x, 14)
    o != 0 && return FlatBuffers.get(x, o + FlatBuffers.pos(x), Int32)
    return Int32(-1)
end

function Base.getindex(x::Column, ::Type{ColumnProperties.scale})
    #GetScalarFieldOfTable
    o = FlatBuffers.offset(x, 16)
    o != 0 && return FlatBuffers.get(x, o + FlatBuffers.pos(x), Int32)
    return Int32(-1)
end

function Base.getindex(x::Column, ::Type{ColumnProperties.nullable})
    #GetScalarFieldOfTable
    o = FlatBuffers.offset(x, 18)
    o != 0 && return FlatBuffers.get(x, o + FlatBuffers.pos(x), Bool)
    return Bool(true)
end

function Base.getindex(x::Column, ::Type{ColumnProperties.unique})
    #GetScalarFieldOfTable
    o = FlatBuffers.offset(x, 20)
    o != 0 && return FlatBuffers.get(x, o + FlatBuffers.pos(x), Bool)
    return Bool(false)
end

function Base.getindex(x::Column, ::Type{ColumnProperties.primaryKey})
    #GetScalarFieldOfTable
    o = FlatBuffers.offset(x, 22)
    o != 0 && return FlatBuffers.get(x, o + FlatBuffers.pos(x), Bool)
    return Bool(false)
end

function Base.getindex(x::Column, ::Type{ColumnProperties.metadata})
    #GetStringField
    o = FlatBuffers.offset(x, 24)
    o != 0 && return String(x, o + FlatBuffers.pos(x))
    return string(0)
    return nothing
end


ColumnStart(b::FlatBuffers.Builder) = FlatBuffers.startobject!(b, 11)
ColumnAddName(b::FlatBuffers.Builder, name::FlatBuffers.UOffsetT) = FlatBuffers.prependoffsetslot!(b, 0, name, 0)
ColumnAddType(b::FlatBuffers.Builder, type::ColumnType) = FlatBuffers.prependslot!(b, 1, type, 0)
ColumnAddTitle(b::FlatBuffers.Builder, title::FlatBuffers.UOffsetT) = FlatBuffers.prependoffsetslot!(b, 2, title, 0)
ColumnAddDescription(b::FlatBuffers.Builder, description::FlatBuffers.UOffsetT) = FlatBuffers.prependoffsetslot!(b, 3, description, 0)
ColumnAddWidth(b::FlatBuffers.Builder, width::Int32) = FlatBuffers.prependslot!(b, 4, width, -1)
ColumnAddPrecision(b::FlatBuffers.Builder, precision::Int32) = FlatBuffers.prependslot!(b, 5, precision, -1)
ColumnAddScale(b::FlatBuffers.Builder, scale::Int32) = FlatBuffers.prependslot!(b, 6, scale, -1)
ColumnAddNullable(b::FlatBuffers.Builder, nullable::Bool) = FlatBuffers.prependslot!(b, 7, nullable, true)
ColumnAddUnique(b::FlatBuffers.Builder, unique::Bool) = FlatBuffers.prependslot!(b, 8, unique, false)
ColumnAddPrimaryKey(b::FlatBuffers.Builder, primaryKey::Bool) = FlatBuffers.prependslot!(b, 9, primaryKey, false)
ColumnAddMetadata(b::FlatBuffers.Builder, metadata::FlatBuffers.UOffsetT) = FlatBuffers.prependoffsetslot!(b, 10, metadata, 0)
ColumnEnd(b::FlatBuffers.Builder) = FlatBuffers.endobject!(b)

struct Crs <: FlatBuffers.Table
    bytes::Vector{UInt8}
    pos::Base.Int
end

Base.propertynames(::Crs) = (
    :org,
    :code,
    :name,
    :description,
    :wkt,
    :codeString,
)

function Base.getproperty(x::Crs, field::Symbol)
    if field === :org
        #GetStringField
        o = FlatBuffers.offset(x, 4)
        o != 0 && return String(x, o + FlatBuffers.pos(x))
        return string(0)
    elseif field === :code
        #GetScalarFieldOfTable
        o = FlatBuffers.offset(x, 6)
        o != 0 && return FlatBuffers.get(x, o + FlatBuffers.pos(x), Int32)
        return Int32(0)
    elseif field === :name
        #GetStringField
        o = FlatBuffers.offset(x, 8)
        o != 0 && return String(x, o + FlatBuffers.pos(x))
        return string(0)
    elseif field === :description
        #GetStringField
        o = FlatBuffers.offset(x, 10)
        o != 0 && return String(x, o + FlatBuffers.pos(x))
        return string(0)
    elseif field === :wkt
        #GetStringField
        o = FlatBuffers.offset(x, 12)
        o != 0 && return String(x, o + FlatBuffers.pos(x))
        return string(0)
    elseif field === :codeString
        #GetStringField
        o = FlatBuffers.offset(x, 14)
        o != 0 && return String(x, o + FlatBuffers.pos(x))
        return string(0)
    end
    return nothing
end

module CrsProperties
abstract type AbstractProperty end
struct org <: AbstractProperty end
struct code <: AbstractProperty end
struct name <: AbstractProperty end
struct description <: AbstractProperty end
struct wkt <: AbstractProperty end
struct codeString <: AbstractProperty end
end

function Base.getindex(x::Crs, ::Type{CrsProperties.org})
    #GetStringField
    o = FlatBuffers.offset(x, 4)
    o != 0 && return String(x, o + FlatBuffers.pos(x))
    return string(0)
    return nothing
end

function Base.getindex(x::Crs, ::Type{CrsProperties.code})
    #GetScalarFieldOfTable
    o = FlatBuffers.offset(x, 6)
    o != 0 && return FlatBuffers.get(x, o + FlatBuffers.pos(x), Int32)
    return Int32(0)
end

function Base.getindex(x::Crs, ::Type{CrsProperties.name})
    #GetStringField
    o = FlatBuffers.offset(x, 8)
    o != 0 && return String(x, o + FlatBuffers.pos(x))
    return string(0)
    return nothing
end

function Base.getindex(x::Crs, ::Type{CrsProperties.description})
    #GetStringField
    o = FlatBuffers.offset(x, 10)
    o != 0 && return String(x, o + FlatBuffers.pos(x))
    return string(0)
    return nothing
end

function Base.getindex(x::Crs, ::Type{CrsProperties.wkt})
    #GetStringField
    o = FlatBuffers.offset(x, 12)
    o != 0 && return String(x, o + FlatBuffers.pos(x))
    return string(0)
    return nothing
end

function Base.getindex(x::Crs, ::Type{CrsProperties.codeString})
    #GetStringField
    o = FlatBuffers.offset(x, 14)
    o != 0 && return String(x, o + FlatBuffers.pos(x))
    return string(0)
    return nothing
end


CrsStart(b::FlatBuffers.Builder) = FlatBuffers.startobject!(b, 6)
CrsAddOrg(b::FlatBuffers.Builder, org::FlatBuffers.UOffsetT) = FlatBuffers.prependoffsetslot!(b, 0, org, 0)
CrsAddCode(b::FlatBuffers.Builder, code::Int32) = FlatBuffers.prependslot!(b, 1, code, 0)
CrsAddName(b::FlatBuffers.Builder, name::FlatBuffers.UOffsetT) = FlatBuffers.prependoffsetslot!(b, 2, name, 0)
CrsAddDescription(b::FlatBuffers.Builder, description::FlatBuffers.UOffsetT) = FlatBuffers.prependoffsetslot!(b, 3, description, 0)
CrsAddWkt(b::FlatBuffers.Builder, wkt::FlatBuffers.UOffsetT) = FlatBuffers.prependoffsetslot!(b, 4, wkt, 0)
CrsAddCodeString(b::FlatBuffers.Builder, codeString::FlatBuffers.UOffsetT) = FlatBuffers.prependoffsetslot!(b, 5, codeString, 0)
CrsEnd(b::FlatBuffers.Builder) = FlatBuffers.endobject!(b)

struct Header <: FlatBuffers.Table
    bytes::Vector{UInt8}
    pos::Base.Int
end

Base.propertynames(::Header) = (
    :name,
    :envelope,
    :geometryType,
    :hasZ,
    :hasM,
    :hasT,
    :hasTm,
    :columns,
    :featuresCount,
    :indexNodeSize,
    :crs,
    :title,
    :description,
    :metadata,
)

function Base.getproperty(x::Header, field::Symbol)
    if field === :name
        #GetStringField
        o = FlatBuffers.offset(x, 4)
        o != 0 && return String(x, o + FlatBuffers.pos(x))
        return string(0)
    elseif field === :envelope
        #GetMemberOfVectorOfNonStruct
        o = FlatBuffers.offset(x, 6)
        o != 0 && return FlatBuffers.Array{Float64}(x, o)
    elseif field === :geometryType
        #GetScalarFieldOfTable
        o = FlatBuffers.offset(x, 8)
        o != 0 && return FlatBuffers.get(x, o + FlatBuffers.pos(x), GeometryType)
        return GeometryType(0)
    elseif field === :hasZ
        #GetScalarFieldOfTable
        o = FlatBuffers.offset(x, 10)
        o != 0 && return FlatBuffers.get(x, o + FlatBuffers.pos(x), Bool)
        return Bool(false)
    elseif field === :hasM
        #GetScalarFieldOfTable
        o = FlatBuffers.offset(x, 12)
        o != 0 && return FlatBuffers.get(x, o + FlatBuffers.pos(x), Bool)
        return Bool(false)
    elseif field === :hasT
        #GetScalarFieldOfTable
        o = FlatBuffers.offset(x, 14)
        o != 0 && return FlatBuffers.get(x, o + FlatBuffers.pos(x), Bool)
        return Bool(false)
    elseif field === :hasTm
        #GetScalarFieldOfTable
        o = FlatBuffers.offset(x, 16)
        o != 0 && return FlatBuffers.get(x, o + FlatBuffers.pos(x), Bool)
        return Bool(false)
    elseif field === :columns
        #GetMemberOfVectorOfStruct
        o = FlatBuffers.offset(x, 18)
        o != 0 && return FlatBuffers.Array{Column}(x, o)
    elseif field === :featuresCount
        #GetScalarFieldOfTable
        o = FlatBuffers.offset(x, 20)
        o != 0 && return FlatBuffers.get(x, o + FlatBuffers.pos(x), UInt64)
        return UInt64(0)
    elseif field === :indexNodeSize
        #GetScalarFieldOfTable
        o = FlatBuffers.offset(x, 22)
        o != 0 && return FlatBuffers.get(x, o + FlatBuffers.pos(x), UInt16)
        return UInt16(16)
    elseif field === :crs
        #GetStructFieldOfTable
        o = FlatBuffers.offset(x, 24)
        if o != 0
            y = FlatBuffers.indirect(x, o + FlatBuffers.pos(x))
            return FlatBuffers.init(Crs, FlatBuffers.bytes(x), y)
        end
    elseif field === :title
        #GetStringField
        o = FlatBuffers.offset(x, 26)
        o != 0 && return String(x, o + FlatBuffers.pos(x))
        return string(0)
    elseif field === :description
        #GetStringField
        o = FlatBuffers.offset(x, 28)
        o != 0 && return String(x, o + FlatBuffers.pos(x))
        return string(0)
    elseif field === :metadata
        #GetStringField
        o = FlatBuffers.offset(x, 30)
        o != 0 && return String(x, o + FlatBuffers.pos(x))
        return string(0)
    end
    return nothing
end

module HeaderProperties
abstract type AbstractProperty end
struct name <: AbstractProperty end
struct envelope <: AbstractProperty end
struct geometryType <: AbstractProperty end
struct hasZ <: AbstractProperty end
struct hasM <: AbstractProperty end
struct hasT <: AbstractProperty end
struct hasTm <: AbstractProperty end
struct columns <: AbstractProperty end
struct featuresCount <: AbstractProperty end
struct indexNodeSize <: AbstractProperty end
struct crs <: AbstractProperty end
struct title <: AbstractProperty end
struct description <: AbstractProperty end
struct metadata <: AbstractProperty end
end

function Base.getindex(x::Header, ::Type{HeaderProperties.name})
    #GetStringField
    o = FlatBuffers.offset(x, 4)
    o != 0 && return String(x, o + FlatBuffers.pos(x))
    return string(0)
    return nothing
end

function Base.getindex(x::Header, ::Type{HeaderProperties.envelope})
    #GetMemberOfVectorOfNonStruct
    o = FlatBuffers.offset(x, 6)
    o != 0 && return FlatBuffers.Array{Float64}(x, o)
    return nothing
end

function Base.getindex(x::Header, ::Type{HeaderProperties.geometryType})
    #GetScalarFieldOfTable
    o = FlatBuffers.offset(x, 8)
    o != 0 && return FlatBuffers.get(x, o + FlatBuffers.pos(x), GeometryType)
    return GeometryType(0)
end

function Base.getindex(x::Header, ::Type{HeaderProperties.hasZ})
    #GetScalarFieldOfTable
    o = FlatBuffers.offset(x, 10)
    o != 0 && return FlatBuffers.get(x, o + FlatBuffers.pos(x), Bool)
    return Bool(false)
end

function Base.getindex(x::Header, ::Type{HeaderProperties.hasM})
    #GetScalarFieldOfTable
    o = FlatBuffers.offset(x, 12)
    o != 0 && return FlatBuffers.get(x, o + FlatBuffers.pos(x), Bool)
    return Bool(false)
end

function Base.getindex(x::Header, ::Type{HeaderProperties.hasT})
    #GetScalarFieldOfTable
    o = FlatBuffers.offset(x, 14)
    o != 0 && return FlatBuffers.get(x, o + FlatBuffers.pos(x), Bool)
    return Bool(false)
end

function Base.getindex(x::Header, ::Type{HeaderProperties.hasTm})
    #GetScalarFieldOfTable
    o = FlatBuffers.offset(x, 16)
    o != 0 && return FlatBuffers.get(x, o + FlatBuffers.pos(x), Bool)
    return Bool(false)
end

function Base.getindex(x::Header, ::Type{HeaderProperties.columns})
    #GetMemberOfVectorOfStruct
    o = FlatBuffers.offset(x, 18)
    o != 0 && return FlatBuffers.Array{Column}(x, o)
    return nothing
end

function Base.getindex(x::Header, ::Type{HeaderProperties.featuresCount})
    #GetScalarFieldOfTable
    o = FlatBuffers.offset(x, 20)
    o != 0 && return FlatBuffers.get(x, o + FlatBuffers.pos(x), UInt64)
    return UInt64(0)
end

function Base.getindex(x::Header, ::Type{HeaderProperties.indexNodeSize})
    #GetScalarFieldOfTable
    o = FlatBuffers.offset(x, 22)
    o != 0 && return FlatBuffers.get(x, o + FlatBuffers.pos(x), UInt16)
    return UInt16(16)
end

function Base.getindex(x::Header, ::Type{HeaderProperties.crs})
    #GetStructFieldOfTable
    o = FlatBuffers.offset(x, 24)
    if o != 0
        y = FlatBuffers.indirect(x, o + FlatBuffers.pos(x))
        return FlatBuffers.init(Crs, FlatBuffers.bytes(x), y)
    end
    return nothing
end

function Base.getindex(x::Header, ::Type{HeaderProperties.title})
    #GetStringField
    o = FlatBuffers.offset(x, 26)
    o != 0 && return String(x, o + FlatBuffers.pos(x))
    return string(0)
    return nothing
end

function Base.getindex(x::Header, ::Type{HeaderProperties.description})
    #GetStringField
    o = FlatBuffers.offset(x, 28)
    o != 0 && return String(x, o + FlatBuffers.pos(x))
    return string(0)
    return nothing
end

function Base.getindex(x::Header, ::Type{HeaderProperties.metadata})
    #GetStringField
    o = FlatBuffers.offset(x, 30)
    o != 0 && return String(x, o + FlatBuffers.pos(x))
    return string(0)
    return nothing
end


HeaderStart(b::FlatBuffers.Builder) = FlatBuffers.startobject!(b, 14)
HeaderAddName(b::FlatBuffers.Builder, name::FlatBuffers.UOffsetT) = FlatBuffers.prependoffsetslot!(b, 0, name, 0)
HeaderAddEnvelope(b::FlatBuffers.Builder, envelope::FlatBuffers.UOffsetT) = FlatBuffers.prependoffsetslot!(b, 1, envelope, 0)
HeaderStartEnvelopeVector(b::FlatBuffers.Builder, numelems::Integer) = FlatBuffers.startvector!(b, 8, numelems, 8)
HeaderAddGeometryType(b::FlatBuffers.Builder, geometryType::GeometryType) = FlatBuffers.prependslot!(b, 2, geometryType, 0)
HeaderAddHasZ(b::FlatBuffers.Builder, hasZ::Bool) = FlatBuffers.prependslot!(b, 3, hasZ, false)
HeaderAddHasM(b::FlatBuffers.Builder, hasM::Bool) = FlatBuffers.prependslot!(b, 4, hasM, false)
HeaderAddHasT(b::FlatBuffers.Builder, hasT::Bool) = FlatBuffers.prependslot!(b, 5, hasT, false)
HeaderAddHasTm(b::FlatBuffers.Builder, hasTm::Bool) = FlatBuffers.prependslot!(b, 6, hasTm, false)
HeaderAddColumns(b::FlatBuffers.Builder, columns::FlatBuffers.UOffsetT) = FlatBuffers.prependoffsetslot!(b, 7, columns, 0)
HeaderStartColumnsVector(b::FlatBuffers.Builder, numelems::Integer) = FlatBuffers.startvector!(b, 4, numelems, 4)
HeaderAddFeaturesCount(b::FlatBuffers.Builder, featuresCount::UInt64) = FlatBuffers.prependslot!(b, 8, featuresCount, 0)
HeaderAddIndexNodeSize(b::FlatBuffers.Builder, indexNodeSize::UInt16) = FlatBuffers.prependslot!(b, 9, indexNodeSize, 16)
HeaderAddCrs(b::FlatBuffers.Builder, crs::FlatBuffers.UOffsetT) = FlatBuffers.prependoffsetslot!(b, 10, crs, 0)
HeaderAddTitle(b::FlatBuffers.Builder, title::FlatBuffers.UOffsetT) = FlatBuffers.prependoffsetslot!(b, 11, title, 0)
HeaderAddDescription(b::FlatBuffers.Builder, description::FlatBuffers.UOffsetT) = FlatBuffers.prependoffsetslot!(b, 12, description, 0)
HeaderAddMetadata(b::FlatBuffers.Builder, metadata::FlatBuffers.UOffsetT) = FlatBuffers.prependoffsetslot!(b, 13, metadata, 0)
HeaderEnd(b::FlatBuffers.Builder) = FlatBuffers.endobject!(b)


end #module
