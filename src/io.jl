
function skipmagic(io::IO)
    magic = read(io, 8)
    magic[1] == 0x66 &&
        magic[2] == 0x67 &&
        magic[3] == 0x62 &&
        magic[4] == 0x03 ||
        error("File has wrong header")
    v = "$(magic[4]).0.$(magic[8])"
    VersionNumber(v)
end


function calc_rtree_nodes(n_items::UInt64, node_size::UInt16)
    node_size = min(max(UInt16(2), node_size), UInt16(65535))
    n_nodes = copy(n_items)
    n = copy(n_items)
    while n != 1
        n = (n + node_size - 1) ÷ node_size
        n_nodes += n
    end
    # @debug "$n_items features with $n_nodes nodes in tree."
    Int64(n_nodes)
end

# :name,
# :envelope,
# :geometryType,
# :hasZ,
# :hasM,
# :hasT,
# :hasTm,
# :columns,
# :featuresCount,
# :indexNodeSize,
# :crs,
# :title,
# :description,
# :metadata,

function read_file(fn)
    io = open(fn)
    skipmagic(io)
    # @debug "Start at offset: $(position(io))"
    header_size = read(io, UInt32)
    # @debug "headerSize: $header_size"
    data = read(io, header_size)
    header = FlatBuffers.getrootas(Gen.Header, data, 0)
    fgb = FlatGeobuffer(header, NodeItem[], io, 0, Int64[], false)
    @info header.crs, header.columns, header.indexNodeSize, header.featuresCount
    rtree_size = 0
    if header.indexNodeSize > 0
        # @debug "Tree start at offset ($(position(io)))"
        n_nodes = calc_rtree_nodes(header.featuresCount, header.indexNodeSize)
        @info n_nodes
        sizehint!(fgb.rtree, n_nodes)
        for _ in 1:n_nodes
            node = read(io, NodeItem)
            push!(fgb.rtree, node)
        end
        rtree_size += n_nodes * sizeof(NodeItem)
        # @debug "Add treeSize to offset ($rtree_size)"
    end
    # @debug "Features start at offset ($(position(io)))"
    fgb.offset = position(io)
    fgb
end


function split_properties(x, columns)
    offset = 1
    @info columns
    cnames = Tuple(map(x -> Symbol(x.name), columns))
    cvalues = []
    for (i, column) in enumerate(columns)
        name = cnames[i]
        @info name
        if offset + sizeof(UInt16) > length(x)
            push!(cvalues, missing)
            continue
        end
        key = reinterpret(UInt16, view(x, offset:offset+sizeof(UInt16)-1))[1]
        if key != (i - 1)
            push!(cvalues, missing)
            continue
        end
        offset += sizeof(UInt16)
        t = lookup(column.type)
        if t == String
            size = reinterpret(UInt32, view(x, offset:offset+sizeof(UInt32)-1))[1]
            offset += sizeof(UInt32)
            value = String(view(x, offset:offset+size-1))
            offset += size
            push!(cvalues, value)
        else
            value = reinterpret(t, view(x, offset:offset+sizeof(t)-1))[1]
            offset += sizeof(t)
            push!(cvalues, value)
        end
    end
    ctypes = Tuple{map(x -> x.nullable ? Union{Missing,lookup(x.type)} : lookup(x.type), columns)...}
    NamedTuple{cnames,ctypes}(Tuple(cvalues))
end


"""Iteration of FGB file."""
function Base.iterate(fgb::FlatGeobuffer, state::Int=0)::Union{Nothing,Tuple{eltype(fgb),Int}}
    if state >= (fgb.filtered ? length(fgb.offsets) : fgb.header.featuresCount)
        return nothing
    else
        state == 0 && seek(fgb.io, fgb.offset)
        fgb.filtered && seek(fgb.io, fgb.offsets[state+1] + fgb.offset)
        feature_size = read(fgb.io, UInt32)
        data = read(fgb.io, feature_size)
        f = FlatBuffers.getrootas(Gen.Feature, data, 0)
        props = split_properties(f.properties, fgb.header.columns)
        (props..., geom=f.geometry), state + 1
    end
end

# function test(fgb::FlatGeobuffer, state::Int=0)
#     if state >= (fgb.filtered ? length(fgb.offsets) : fgb.header.featuresCount)
#         return nothing
#     else
#         state == 0 && seek(fgb.io, fgb.offset)
#         fgb.filtered && seek(fgb.io, fgb.offsets[state+1] + fgb.offset)
#         feature_size = read(fgb.io, UInt32)
#         return Feature(read(fgb.io, feature_size))
#     end
# end
# Base.collect(fgb::FlatGeobuffer) = Base.collect(Base.eltype(fgb), fgb)::Vector{Base.eltype(fgb)}
Base.eltype(fgb::FlatGeobuffer) = NamedTuple{(Tuple(map(x -> Symbol(x.name), fgb.header.columns))..., :geom),Tuple{(map(x -> x.nullable ? Union{Missing,lookup(x.type)} : lookup(x.type), fgb.header.columns)..., Gen.Geometry)...}}

Base.length(fgb::FlatGeobuffer)::Int64 = fgb.filtered ? length(fgb.offsets) : Int64(fgb.header.featuresCount)
