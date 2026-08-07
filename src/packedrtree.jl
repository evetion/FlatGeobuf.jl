# PackedRTree - A view over a flat-packed R-tree array
# Implements the SpatialTreeInterface from GeometryOps.jl

using Extents

# Interface trait for packed rtree node elements
# Implement these for your node element type to use PackedRTree

"""
    node_extent(node)

Return the Extent of a packed rtree node element.
"""
function node_extent end

"""
    node_offset(node)

Return the offset stored in a packed rtree node element.
For internal nodes, this is the index of the first child.
For leaf nodes, this is the feature identifier/offset.
"""
function node_offset end

# Implementation for NodeItem
node_extent(node::NodeItem) = Extent(X=(node.min_x, node.max_x), Y=(node.min_y, node.max_y))
node_offset(node::NodeItem) = node.offset

"""
    PackedRTree{T, V}

Wrapper around a flat-packed R-tree stored as a contiguous array.
This provides a hierarchical view over the flat array structure.

The flat array layout follows the FlatGeobuf specification:
- Nodes are stored level by level, root first
- Internal nodes store child offset in their offset field
- Leaf nodes store feature identifiers in their offset field
"""
struct PackedRTree{T, V <: AbstractVector{T}}
    nodes::V              # The flat array of nodes
    node_size::Int        # Branching factor (max children per internal node)
    n_features::Int       # Number of features (= number of leaf nodes)
    n_non_leaves::Int     # nodes[1:n_non_leaves] are internal nodes
end

"""
    PackedRTree(nodes::AbstractVector, node_size::Integer, n_features::Integer)

Construct a PackedRTree from a flat array of nodes.
"""
function PackedRTree(nodes::V, node_size::Integer, n_features::Integer) where {T, V <: AbstractVector{T}}
    n_non_leaves = length(nodes) - n_features
    PackedRTree{T, V}(nodes, Int(node_size), Int(n_features), n_non_leaves)
end

"""
    PackedRTree(fgb::FlatGeobuffer)

Construct a PackedRTree view over a FlatGeobuffer's spatial index.
"""
function PackedRTree(fgb::FlatGeobuffer)
    PackedRTree(fgb.rtree, fgb.header.index_node_size, fgb.header.features_count)
end

"""
    PackedRTreeNode{T, V}

A view into a single node of a PackedRTree.
Carries reference to tree metadata to compute children and leaf status.
"""
struct PackedRTreeNode{T, V <: AbstractVector{T}}
    tree::PackedRTree{T, V}
    index::Int            # 1-based index into tree.nodes
end

# Get the underlying node element
@inline nodeitem(node::PackedRTreeNode) = node.tree.nodes[node.index]

# === SpatialTreeInterface implementation ===

# Predicate to identify spatial trees
isspatialtree(::Type{<:PackedRTree}) = true
isspatialtree(::Type{<:PackedRTreeNode}) = true
isspatialtree(::T) where T = isspatialtree(T)

# Root node accessor for tree
root(tree::PackedRTree) = PackedRTreeNode(tree, 1)

# node_extent - bounding box of a node
node_extent(tree::PackedRTree) = node_extent(root(tree))
node_extent(node::PackedRTreeNode) = node_extent(nodeitem(node))

# isleaf - check if node is a leaf (stores feature offsets, not child nodes)
isleaf(tree::PackedRTree) = isleaf(root(tree))
isleaf(node::PackedRTreeNode) = node.index > node.tree.n_non_leaves

# nchild - number of children
function nchild(tree::PackedRTree)
    isempty(tree.nodes) && return 0
    nchild(root(tree))
end

function nchild(node::PackedRTreeNode)
    if isleaf(node)
        # Leaf nodes have exactly 1 "child" - their feature reference
        return 1
    else
        # Internal nodes: children start at offset+1, up to node_size children
        # But we need to not exceed the array bounds
        first_child = Int(node_offset(nodeitem(node))) + 1
        max_children = min(node.tree.node_size, length(node.tree.nodes) - first_child + 1)
        return max_children
    end
end

# getchild - get children iterator or specific child
function getchild(tree::PackedRTree)
    isempty(tree.nodes) && return PackedRTreeNode{eltype(tree.nodes), typeof(tree.nodes)}[]
    getchild(root(tree))
end
getchild(tree::PackedRTree, i) = getchild(root(tree), i)

function getchild(node::PackedRTreeNode)
    if isleaf(node)
        # Leaf node returns itself as the single "child" for iteration
        return (node,)
    else
        tree = node.tree
        first_child = Int(node_offset(nodeitem(node))) + 1
        n = nchild(node)
        return (PackedRTreeNode(tree, first_child + i - 1) for i in 1:n)
    end
end

function getchild(node::PackedRTreeNode, i)
    if isleaf(node)
        i == 1 || throw(BoundsError(node, i))
        return node
    else
        first_child = Int(node_offset(nodeitem(node))) + 1
        return PackedRTreeNode(node.tree, first_child + i - 1)
    end
end

# child_indices_extents - iterator over (index, extent) for leaf children
# For leaf nodes, returns the feature offset and extent
function child_indices_extents(node::PackedRTreeNode)
    if !isleaf(node)
        error("child_indices_extents can only be called on leaf nodes")
    end
    item = nodeitem(node)
    # Return single (offset, extent) pair
    # The offset is the feature identifier/file offset
    return ((Int(node_offset(item)), node_extent(item)),)
end

# === Depth-first search implementation ===
# This is a local implementation compatible with SpatialTreeInterface

"""
    depth_first_search(f, predicate, tree::PackedRTree)
    depth_first_search(f, predicate, node::PackedRTreeNode)

Perform depth-first search over the tree, calling `f(index)` for each
leaf node whose extent satisfies `predicate(extent)`.

Returns nothing; results should be accumulated via the callback `f`.
"""
function depth_first_search(f::F, predicate::P, tree::PackedRTree) where {F, P}
    isempty(tree.nodes) && return nothing
    depth_first_search(f, predicate, root(tree))
end

function depth_first_search(f::F, predicate::P, node::PackedRTreeNode) where {F, P}
    if isleaf(node)
        for (idx, ext) in child_indices_extents(node)
            if predicate(ext)
                f(idx)
            end
        end
    else
        for child in getchild(node)
            if predicate(node_extent(child))
                depth_first_search(f, predicate, child)
            end
        end
    end
    return nothing
end

"""
    query(tree::PackedRTree, predicate)

Return a vector of feature indices/offsets that satisfy the predicate.
"""
function query(tree::PackedRTree, predicate)
    results = Int[]
    depth_first_search(Base.Fix1(push!, results), predicate, tree)
    return results
end
