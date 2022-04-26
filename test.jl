using FlatGeobuf
fna = "test/countries.fgb"
io = open(fna)
FlatGeobuf.skipmagic(io)
header_size = read(io, UInt32)
data = read(io, header_size)
header = FlatGeobuf.FlatBuffers.getrootas(FlatGeobuf.Gen.Header, data, 0);
