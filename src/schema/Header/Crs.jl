# automatically generated by the FlatBuffers compiler, do not modify



FlatBuffers.@with_kw mutable struct Crs
    org::String = ""
    code::Int32 = 0
    name::String = ""
    description::String = ""
    wkt::String = ""
    code_string::String = ""
end
FlatBuffers.@ALIGN(Crs, 1)
FlatBuffers.slot_offsets(::Type{T}) where {T <: Crs} = [
    0x00000004, 0x00000006, 0x00000008, 0x0000000A,
    0x0000000C, 0x0000000E
]

Crs(buf::AbstractVector{UInt8}) = FlatBuffers.read(Crs, buf)
Crs(io::IO) = FlatBuffers.deserialize(io, Crs)
