# automatically generated by the FlatBuffers compiler, do not modify

FlatGeoBuf.eval(quote


FlatBuffers.@with_kw mutable struct Feature
    geometry::Union{Geometry, Nothing} = nothing
    properties::Vector{UInt8} = []
    columns::Vector{Column} = []
end
# FlatBuffers.@ALIGN(Feature, 1)
FlatBuffers.slot_offsets(::Type{T}) where {T<:Feature} = [
    0x00000004, 0x00000006, 0x00000008
]
FlatBuffers.root_type(::Type{T}) where {T<:Feature} = true

Feature(buf::AbstractVector{UInt8}) = FlatBuffers.read(Feature, buf)
Feature(io::IO) = FlatBuffers.deserialize(io, Feature)

end)
