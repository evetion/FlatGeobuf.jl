using Test
using FlatGeobuf
using FlatBuffers
using Tables
using DataFrames
using Extents
using Downloads
using GeoInterface

@testset "FlatGeobuf" begin
    fna = "countries.fgb"
    fnb = "UScounties.fgb"
    isfile(fna) || Downloads.download("https://github.com/bjornharrtell/flatgeobuf/blob/master/test/data/countries.fgb?raw=true", fna)
    isfile(fnb) || Downloads.download("https://github.com/bjornharrtell/flatgeobuf/blob/master/test/data/UScounties.fgb?raw=true", fnb)

    @testset "Construction" begin
        crs = FlatGeobuf.Crs("epsg", 28992, "RD New", "Dutch grid", "proj+=asdas", "codestring")
        h = FlatGeobuf.Header(name="test", crs=crs)
        g = FlatGeobuf.Geometry()
    end

    @testset "Serializing and parsing" begin
        crs = FlatGeobuf.Crs("epsg", 28992, "RD New", "Dutch grid", "proj+=asdas", "codestring")
        h = FlatGeobuf.Header(name="test", crs=crs)

        # Write header
        open("example.bin", "w") do f
            FlatBuffers.serialize(f, h)
        end
        # Read header again
        nh = open("example.bin", "r") do f
            FlatBuffers.deserialize(f, FlatGeobuf.Header)
        end

        # Assert it's similar
        @test h.crs.wkt == nh.crs.wkt
    end

    @testset "Using testfiles" begin
        fgb = FlatGeobuf.read(fnb)
        features = collect(fgb)
        @test length(features) == 3221

        filter!(fgb, [-92.73405699999999, 32.580974999999995, -92.73405699999999, 32.580974999999995])
        features = collect(fgb)
        @test length(features) == 2

        fgb = FlatGeobuf.read(joinpath(@__DIR__, "null.fgb"))
        t = DataFrame(fgb)
        @test ismissing(t.date[2])
        @test ismissing(t.name[2])
        @test ismissing(t.number[2])
    end

    @testset "Filter" begin
        fgb = FlatGeobuf.read(fna)
        @test length(fgb) == 179
        ex = Extent(X=(-92.73405699999999, -92.73405699999999), Y=(32.580974999999995, 32.580974999999995))
        filter!(fgb, ex)
        @test length(fgb) == 2
    end

    @testset "GeoInterface" begin
        fgb = FlatGeobuf.read(fna)
        @test GeoInterface.testfeaturecollection(fgb)
        @test GeoInterface.testfeature(iterate(fgb)[1])
        @test GeoInterface.testgeometry(iterate(fgb)[1].geometry)

        fgb = FlatGeobuf.read(fnb)
        @test GeoInterface.testfeaturecollection(fgb)
        @test GeoInterface.testfeature(iterate(fgb)[1])
        @test GeoInterface.testgeometry(iterate(fgb)[1].geometry)

        # The hole of South Africa starts after the end of the exterior ring
        fgb = FlatGeobuf.read(fna)
        zaf = first(f for f in fgb if GeoInterface.properties(f).id == "ZAF")
        hole = GeoInterface.coordinates(GeoInterface.getgeom(GeoInterface.getgeom(zaf.geometry, 1), 2))
        @test length(hole) == 12
        @test hole[1] == hole[end] == [28.978263, -28.955597]

        mls = FlatGeobuf.Geometry(xy=[0.0, 0.0, 1.0, 1.0, 2.0, 2.0, 3.0, 3.0], tm=UInt64[1, 2, 3, 4], ends=UInt32[2, 4], type=FlatGeobuf.GeometryTypeMultiLineString)
        @test GeoInterface.getgeom(mls, 2).xy == [2.0, 2.0, 3.0, 3.0]
        @test GeoInterface.getgeom(mls, 2).tm == UInt64[3, 4]
    end
end
