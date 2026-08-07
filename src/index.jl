using Extents

function Base.read(io::IO, ::Type{NodeItem})
    NodeItem(
        Base.read(io, Float64),
        Base.read(io, Float64),
        Base.read(io, Float64),
        Base.read(io, Float64),
        Base.read(io, UInt64)
    )
end

Base.convert(::Type{Extent}, node::NodeItem) = Extent(X=(node.min_x, node.max_x), Y=(node.min_y, node.max_y))
Base.convert(::Type{NodeItem}, ex::Extent) = NodeItem(ex.X[1], ex.Y[1], ex.X[2], ex.Y[2], 0)

"""
    intersects(a::Extent, b::Extent)

Check if two extents intersect (AABB intersection test).
"""
function intersects(a::Extent, b::Extent)
    !(
        a.X[1] > b.X[2] ||
        a.Y[1] > b.Y[2] ||
        a.X[2] < b.X[1] ||
        a.Y[2] < b.Y[1]
    )
end

"""
    search(tree::PackedRTree, bbox::Extent)

Search the packed R-tree for all features intersecting the bounding box.
Returns a vector of feature offsets.

This uses the SpatialTreeInterface's depth_first_search internally.
"""
function search(tree::PackedRTree, bbox::Extent)
    predicate = ext -> intersects(ext, bbox)
    query(tree, predicate)
end

# Legacy interface for backwards compatibility
function search(nodes::Vector{NodeItem}, bbox::NodeItem, nfeatures::UInt64, node_size::UInt16)
    tree = PackedRTree(nodes, node_size, nfeatures)
    bbox_extent = convert(Extent, bbox)
    search(tree, bbox_extent)
end

"""Find all features within a given bounding box."""
function Base.filter(fgb::FlatGeobuffer, bboxv::Vector{<:Real})
    bbox = Extent(X=(bboxv[1], bboxv[3]), Y=(bboxv[2], bboxv[4]))
    tree = PackedRTree(fgb)
    results = search(tree, bbox)
    # Results has offsets into file, but we already parsed the file
    # So we use the offsets to find the relative location of features
    leaf_offsets = sort(map(x -> Int(x.offset), fgb.rtree[end-Int(fgb.header.features_count)+1:end]))
    fgb.features[findfirst.(isequal.(results), Ref(leaf_offsets))]
end

function Base.filter!(fgb::FlatGeobuffer, bboxv::Vector{<:Real})
    bbox = Extent(X=(bboxv[1], bboxv[3]), Y=(bboxv[2], bboxv[4]))
    Base.filter!(fgb, bbox)
end

Base.filter!(fgb::FlatGeobuffer, ex::Extent) = begin
    tree = PackedRTree(fgb)
    fgb.offsets = search(tree, ex)
    fgb.filtered = true
    fgb
end
