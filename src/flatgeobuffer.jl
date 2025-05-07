
struct NodeItem
    min_x::Float64
    min_y::Float64
    max_x::Float64
    max_y::Float64
    offset::UInt64
end

mutable struct FlatGeobuffer
    header::Header
    rtree::Vector{NodeItem}
    io::IO
    offset::Int
    offsets::Vector{Int}
    filtered::Bool
end

Base.show(io::IO, fgb::FlatGeobuffer) = print(io, "$(fgb.filtered ? "Filtered " : "")FlatGeobuffer with $(length(fgb)) $(fgb.header.geometry_type) features.")

Base.:(==)(x::FlatGeobuffer, y::FlatGeobuffer) = x.header == y.header && x.rtree == y.rtree && x.offsets == y.offsets && x.filtered == y.filtered
Base.:(==)(x::Geometry, y::Geometry) = x.ends == y.ends && x.xy == y.xy && x.z == y.z && x.m == y.m && x.t == y.t && x.tm == y.tm && x.type == y.type && x.parts == y.parts
Base.:(==)(x::Feature, y::Feature) = x.geometry == y.geometry && x.properties == y.properties && x.columns == y.columns
