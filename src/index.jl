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
Base.convert(Extent, node::NodeItem) = Extent(X=(node.min_x, node.max_x), Y=(node.min_y, node.max_y))
Base.convert(NodeItem, ex::Extent) = NodeItem(ex.X[1], ex.Y[1], ex.X[2], ex.Y[2], 0)

function intersects(a::NodeItem, b::NodeItem)
    !(
        a.min_x > b.max_x ||
        a.min_y > b.max_y ||
        a.max_x < b.min_x ||
        a.max_y < b.min_y
    )
end

function search(nodes::Vector{NodeItem}, bbox::NodeItem, nfeatures::UInt64, node_size::UInt16)
    # Queue stores both order, as the nodes
    queue = Vector{Tuple{Int64,NodeItem}}([(1, nodes[1])])
    offsets = Vector{Int}()

    # First n nodes are part of tree and have offsets to other nodes
    # while afterwards the nodes are terminal and the offsets point to the features
    n_non_leaves = length(nodes) - nfeatures
    while (length(queue) != 0)
        (i, node) = pop!(queue)
        if intersects(bbox, node)
            if i <= n_non_leaves
                # Still part of tree, add all child nodes to queue
                leaves = Int(node.offset + 1):Int(node.offset + 1)+Int(node_size)-1
                append!(queue, zip(leaves, nodes[leaves]))
            else
                # Or terminal node
                push!(offsets, node.offset)  # Depth first traversal
            end
        end
    end
    offsets
end


"""Find all features within a given bounding box."""
function Base.filter(fgb::FlatGeobuffer, bboxv::Vector{<:Real})
    bbox = NodeItem(bboxv[1], bboxv[2], bboxv[3], bboxv[4], 0)
    results = search(fgb.rtree, bbox, fgb.header.features_count, fgb.header.index_node_size)
    # Results has offsets into file, but we already parsed the file
    # So we use the offsets to find the relative location of features
    offsets = sort(map(x -> x.offset, nodes[end-nfeatures+1:end]))
    fgb.features[findfirst.(isequal.(results), Ref(offsets))]
end

function Base.filter!(fgb::FlatGeobuffer, bboxv::Vector{<:Real})
    bbox = NodeItem(bboxv[1], bboxv[2], bboxv[3], bboxv[4], 0)
    Base.filter!(fgb, bbox)
end
Base.filter!(fgb::FlatGeobuffer, ex::Extent) = Base.filter!(fgb, convert(NodeItem, ex))

function Base.filter!(fgb::FlatGeobuffer, bbox::NodeItem)
    fgb.offsets = search(fgb.rtree, bbox, fgb.header.features_count, fgb.header.index_node_size)
    fgb.filtered = true
    fgb
end
