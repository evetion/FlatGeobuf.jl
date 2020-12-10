using Test
using FlatGeoBuf
using FlatBuffers

fna = "countries.fgb"
fnb = "UScounties.fgb"
isfile(fna) || download("https://github.com/bjornharrtell/flatgeobuf/blob/master/test/data/countries.fgb?raw=true", fna)
isfile(fnb) || download("https://github.com/bjornharrtell/flatgeobuf/blob/master/test/data/UScounties.fgb?raw=true", fnb)


crs = FlatGeoBuf.Crs("epsg", 28992, "RD New", "Dutch grid", "proj+=asdas", "codestring")
h = FlatGeoBuf.Header(name="test", crs=crs)

g = FlatGeoBuf.Geometry()
@info g

open("example.bin", "w") do f FlatBuffers.serialize(f, h) end
nh = open("example.bin", "r") do f
    FlatBuffers.deserialize(f, FlatGeoBuf.Header)
end
@info nh
@info nh.crs
@info h.crs === nh.crs
@info h === nh

skipmagic(io::IO) = seek(io, 8)
skipmagic(buf::AbstractVector{UInt8}) = view(buf, 8:length(buf))

data = FlatGeoBuf.read_file(fnb)
# @testset "Magic" begin
#     @info data[1:4]
#     @test data[1] == 0x66
#     @test data[2] == 0x67
#     @test data[3] == 0x62
#     @test data[4] == 0x03
# end
# skipmagic(data)
# headersize = data[]
# FlatGeoBuf.Header(data)
