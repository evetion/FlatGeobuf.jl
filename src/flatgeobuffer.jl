
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
