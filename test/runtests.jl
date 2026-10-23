using Test
using FlatGeobuf
using FlatBuffers
using Tables
using DataFrames
using Extents
using Downloads
using GeoInterface
using GeoFormatTypes

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
        # Features without a geometry type have the header type
        @test GeoInterface.geomtrait(t.geometry[1]) == GeoInterface.PointTrait()
        @test GeoInterface.geomtrait(fgb[1].geometry) == GeoInterface.PointTrait()
    end

    @testset "Indexing" begin
        fgb = FlatGeobuf.read(fna)
        features = collect(fgb)
        @test fgb[2] == features[2]
        @test fgb[length(fgb)] == features[end]
        @test GeoInterface.getfeature(fgb, 3) == features[3]
        @test_throws BoundsError fgb[length(fgb) + 1]
        fgb.rtree = FlatGeobuf.NodeItem[]  # as without an index
        @test fgb[2] == features[2]
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

        # Collections store their Z values in their parts
        poly = FlatGeobuf.Geometry(xy=[0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0, 0.0], z=[1.0, 2.0, 3.0, 1.0], type=FlatGeobuf.GeometryTypePolygon)
        mp = FlatGeobuf.Geometry(parts=[poly], type=FlatGeobuf.GeometryTypeMultiPolygon)
        @test GeoInterface.is3d(mp) && !GeoInterface.ismeasured(mp)
        @test GeoInterface.ncoord(mp) == 3
        # M without Z
        point = FlatGeobuf.Geometry(xy=[1.0, 2.0], m=[4.0], type=FlatGeobuf.GeometryTypePoint)
        @test !GeoInterface.is3d(point) && GeoInterface.ismeasured(point)
        @test GeoInterface.m(point) == 4.0
        @test GeoInterface.coordinates(point) == [1.0, 2.0, 4.0]

        wkt = "GEOGCS[\"WGS 84\",DATUM[\"WGS_1984\",SPHEROID[\"WGS 84\",6378137,298.257223563]],PRIMEM[\"Greenwich\",0],UNIT[\"degree\",0.0174532925199433]]"
        header = FlatGeobuf.Header(crs=FlatGeobuf.Crs(wkt=wkt))
        @test GeoInterface.crs(FlatGeobuf.FlatGeobuffer(header, [], IOBuffer(), 0, [], false)) == WellKnownText(GeoFormatTypes.CRS(), wkt)
    end
end
