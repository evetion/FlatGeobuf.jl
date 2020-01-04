skipmagic(io::IO) = seek(io, 8)
skipmagic(buf::AbstractVector{UInt8}) = view(buf, 8:length(buf))

io = open("data/UScounties.fgb")
skipmagic(io)
