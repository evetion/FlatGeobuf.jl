using Test
using FlatGeoBuf
using FlatBuffers

fna = "countries.fgb"
fnb = "UScounties.fgb"
isfile(fna) || download("https://github.com/bjornharrtell/flatgeobuf/blob/master/test/data/countries.fgb?raw=true", fna)
isfile(fnb) || download("https://github.com/bjornharrtell/flatgeobuf/blob/master/test/data/UScounties.fgb?raw=true", fnb)


crs = FlatGeoBuf.Crs("epsg", 28992, "RD New", "Dutch grid", "proj+=asdas")
h = FlatGeoBuf.Header(name="test", crs=crs)

open("example.bin", "w") do f FlatBuffers.serialize(f, h) end
nh = open("example.bin", "r") do f
   FlatBuffers.deserialize(f, FlatGeoBuf.Header)
end
@info h.crs == nh.crs
@info h == nh

skipmagic(io::IO) = seek(io, 8)
skipmagic(buf::AbstractVector{UInt8}) = view(buf, 8:length(buf))

data = read(fna)
skipmagic(data)
FlatGeoBuf.Header(data)
