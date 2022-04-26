using Test
using FlatGeobuf
using FlatBuffers
using Tables
using DataFrames
using Downloads

@testset "FlatGeobuf" begin
    fna = "countries.fgb"
    fnb = "UScounties.fgb"
    isfile(fna) || Downloads.download("https://github.com/bjornharrtell/flatgeobuf/blob/master/test/data/countries.fgb?raw=true", fna)
    isfile(fnb) || Downloads.download("https://github.com/bjornharrtell/flatgeobuf/blob/master/test/data/UScounties.fgb?raw=true", fnb)

    @testset "Construction" begin
        crs = FlatGeobuf.Crs("epsg", 28992, "RD New", "Dutch grid", "proj+=asdas", "codestring")
        h = FlatGeobuf.Header(name="test", crs=crs)
        # g = FlatGeobuf.Geometry()
    end

    @testset "Serializing and parsing" begin
        crs = FlatGeobuf.Crs("epsg", 28992, "RD New", "Dutch grid", "proj+=asdas", "codestring")
        h = FlatGeobuf.Header(name="test", crs=crs)

        # Write header
        open("example.bin", "w") do f
            @time FlatBuffers.serialize(f, h)
        end
        # Read header again
        nh = open("example.bin", "r") do f
            @time FlatBuffers.deserialize(f, FlatGeobuf.Header)
        end

        # Assert it's similar
        @test h.crs.wkt == nh.crs.wkt
    end

    @testset "Using testfiles" begin
        fgb = FlatGeobuf.read_file(fnb)
        @time features = collect(fgb)
        @test length(features) == 3221

        @time filter!(fgb, [-92.73405699999999, 32.580974999999995, -92.73405699999999, 32.580974999999995])
        @time features = collect(fgb)
        @test length(features) == 2

        fgb = FlatGeobuf.read_file(joinpath(@__DIR__, "null.fgb"))
        @time t = DataFrame(fgb)
        @test ismissing(t.date[2])
        @test ismissing(t.name[2])
        @test ismissing(t.number[2])
    end
end
