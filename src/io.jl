
function skipmagic(io::IO)
    magic = Base.read(io, 8)
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


# Read a size prefixed flatbuffer, checking that the size fits in the rest of the file
function read_sizeprefixed(io::IO)
    n = Base.read(io, UInt32)
    8 <= n <= filesize(io) - position(io) || error("Invalid size $n at position $(position(io) - 4).")
    Base.read(io, n)
end

@deprecate read_file(filename::AbstractString) read(filename)

function read(fn)
    io = open(fn)
    skipmagic(io)
    @debug "Start at offset: $(position(io))"
    header = Header(read_sizeprefixed(io))
    fgb = FlatGeobuffer(header, [], io, 0, [], false)
    @debug header, header.crs, header.columns
    # Each feature takes at least 12 bytes, and with an index also a leaf node
    min_size = 12 + (header.index_node_size > 0) * sizeof(NodeItem)
    header.features_count <= (filesize(io) - position(io)) ÷ min_size || error("The $(header.features_count) features don't fit in the file.")
    rtree_size = 0
    if header.index_node_size > 0
        header.index_node_size >= 2 || error("Invalid index node size $(header.index_node_size).")
        header.features_count > 0 || error("Index without features.")
        @debug "Tree start at offset ($(position(io)))"
        n_nodes = calc_rtree_nodes(header.features_count, header.index_node_size)
        sizehint!(fgb.rtree, n_nodes)
        for i in 1:n_nodes
            node = Base.read(io, NodeItem)
            push!(fgb.rtree, node)
        end
        rtree_size += n_nodes * sizeof(NodeItem)
        @debug "Add treeSize to offset ($rtree_size)"
    end
    @debug "Features start at offset ($(position(io)))"
    fgb.offset = position(io)
    fgb
end


function _getproperty(x::Vector{UInt8}, i, columns)
    offset = 1
    while offset < length(x)
        if offset + sizeof(UInt16) > length(x)
            return missing
        end
        key = reinterpret(UInt16, view(x, offset:offset+sizeof(UInt16)-1))[1]
        offset += sizeof(UInt16)
        column = columns[key+1]
        t = lookup[column.type]
        if t == String
            size = reinterpret(UInt32, view(x, offset:offset+sizeof(UInt32)-1))[1]
            offset += sizeof(UInt32)
            if i == key + 1
                value = String(view(x, offset:offset+size-1))
                return value
            end
            offset += size
        else
            if i == key + 1
                value = reinterpret(t, view(x, offset:offset+sizeof(t)-1))[1]
                return value
            end
            offset += sizeof(t)
        end
    end
    return missing
end

function split_properties(x::Array{UInt8,1}, columns::Vector{Column})
    offset = 1
    cvalues = []
    for (i, column) in enumerate(columns)
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
        t = lookup[column.type]
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
    cnames = Tuple(map(x -> Symbol(x.name), columns))
    ctypes = Tuple{map(x -> x.nullable ? Union{Missing,lookup[x.type]} : lookup[x.type], columns)...}
    NamedTuple{cnames,ctypes}(Tuple(cvalues))
end

function Base.propertynames(f::Feature)
    names = map(x -> Symbol(x.name), getfield(f, :columns))
    names = push!(names, :geometry)
    names
end

function Base.getproperty(f::Feature, name::Symbol)
    hasfield(Feature, name) && return getfield(f, name)
    i = findfirst(x -> Symbol(getfield(x, :name)) == name, getfield(f, :columns))
    isnothing(i) && error("No such property: $name")
    _getproperty(f.properties, i, f.columns)
end

function Base.convert(::Type{NamedTuple}, f::Feature)
    split_properties(f.properties, f.columns)
end


"""Iteration of FGB file."""
function Base.iterate(fgb::FlatGeobuffer, state::Int=0)
    if state >= (fgb.filtered ? length(fgb.offsets) : fgb.header.features_count)
        return nothing
    else
        state == 0 && seek(fgb.io, fgb.offset)
        fgb.filtered && seek(fgb.io, fgb.offsets[state+1] + fgb.offset)
        f = Feature(read_sizeprefixed(fgb.io))
        isempty(f.columns) && (f.columns = fgb.header.columns)
        f.geometry.type == GeometryTypeUnknown && (f.geometry.type = fgb.header.geometry_type)
        # props = split_properties(f.properties, fgb.header.columns)
        # (props..., geom=f.geometry), state + 1
        f, state + 1
    end
end

function Base.getindex(fgb::FlatGeobuffer, i::Integer)
    if fgb.filtered
        seek(fgb.io, fgb.offsets[i] + fgb.offset)
    else
        1 <= i <= length(fgb) || throw(BoundsError(fgb, i))
        if isempty(fgb.rtree)
            # Skip the size prefixed features before i
            seek(fgb.io, fgb.offset)
            for _ in 1:i-1
                skip(fgb.io, Base.read(fgb.io, UInt32))
            end
        else
            # The leaves of the index hold the offsets of the features, in order
            seek(fgb.io, fgb.rtree[end-length(fgb)+i].offset + fgb.offset)
        end
    end
    f = Feature(read_sizeprefixed(fgb.io))
    isempty(f.columns) && (f.columns = fgb.header.columns)
    f.geometry.type == GeometryTypeUnknown && (f.geometry.type = fgb.header.geometry_type)
    f
end

Base.eltype(fgb::FlatGeobuffer) = Feature
Base.length(fgb::FlatGeobuffer) = fgb.filtered ? length(fgb.offsets) : fgb.header.features_count
