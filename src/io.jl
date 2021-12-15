
function skipmagic(io::IO)
    magic = read(io, 8)
    magic[1] == 0x66 &&
    magic[2] == 0x67 &&
    magic[3] == 0x62 &&
    magic[4] == 0x03 ||
    error("File has wrong header")
end


function calc_rtree_nodes(n_items::UInt64, node_size::UInt16)
    node_size = min(max(UInt16(2), node_size), UInt16(65535))
    n_nodes = copy(n_items)
    n = copy(n_items)
    while n != 1
        n = (n + node_size - 1) ÷ node_size
        n_nodes += n
    end
    @debug "$n_items features with $n_nodes nodes in tree."
    n_nodes
end



function read_file(fn)
    io = open(fn)
    skipmagic(io)
    @debug "Start at offset: $(position(io))"
    header_size = read(io, UInt32)
    @debug "headerSize: $header_size"
    header = Header(read(io, header_size))
    fgb = FlatGeobuffer(header, [], io, 0, [], false)
    @debug header, header.crs, header.columns
    rtree_size = 0
    if header.index_node_size > 0
        @debug "Tree start at offset ($(position(io)))"
        n_nodes = calc_rtree_nodes(header.features_count, header.index_node_size)
        sizehint!(fgb.rtree, n_nodes)
        for i in 1:n_nodes
            node = read(io, NodeItem)
            push!(fgb.rtree, node)
        end
        rtree_size += n_nodes * sizeof(NodeItem)
        @debug "Add treeSize to offset ($rtree_size)"
    end
    @debug "Features start at offset ($(position(io)))"
    fgb.offset = position(io)
    fgb
end


function split_properties(x::Array{UInt8,1}, columns::Vector{Column})
    offset = 1
    cvalues = []
    for (i, column) in enumerate(columns)
        if offset + sizeof(UInt16) > length(x)
            push!(cvalues, missing)
            continue
        end
        key = reinterpret(UInt16, view(x, offset:offset + sizeof(UInt16) - 1))[1]
        if key != (i - 1)
            push!(cvalues, missing)
            continue
        end
        offset += sizeof(UInt16)
        t = lookup[column.type]
        if t == String
            size = reinterpret(UInt32, view(x, offset:offset + sizeof(UInt32) - 1))[1]
            offset += sizeof(UInt32)
            value = String(view(x, offset:offset + size - 1))
            offset += size
            push!(cvalues, value)
        else
            value = reinterpret(t, view(x, offset:offset + sizeof(t) - 1))[1]
            offset += sizeof(t)
            push!(cvalues, value)
        end
    end
    cnames = Tuple(map(x -> Symbol(x.name), columns))
    ctypes = Tuple{map(x -> x.nullable ? Union{Missing,lookup[x.type]} : lookup[x.type], columns)...}
    NamedTuple{cnames,ctypes}(Tuple(cvalues))
end


"""Iteration of FGB file."""
function Base.iterate(fgb::FlatGeobuffer, state::Int=0)
    if state >= (fgb.filtered ? length(fgb.offsets) : fgb.header.features_count)
        return nothing
    else
        state == 0 && seek(fgb.io, fgb.offset)
        fgb.filtered && seek(fgb.io, fgb.offsets[state + 1] + fgb.offset)
        feature_size = read(fgb.io, UInt32)
        f = Feature(read(fgb.io, feature_size))
        props = split_properties(f.properties, fgb.header.columns)
        (props..., geom = f.geometry), state + 1
    end
end

Base.eltype(fgb::FlatGeobuffer) = NamedTuple{(Tuple(map(x -> Symbol(x.name), fgb.header.columns))..., :geom),Tuple{(map(x -> x.nullable ? Union{Missing,lookup[x.type]} : lookup[x.type], fgb.header.columns)..., Geometry)...}}
Base.length(fgb::FlatGeobuffer) = fgb.filtered ? length(fgb.offsets) : fgb.header.features_count
