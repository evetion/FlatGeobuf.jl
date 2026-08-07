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

    @testset "Write and round-trip" begin
        # Read original file
        fgb = FlatGeobuf.read(fna)
        original_features = collect(fgb)

        # Write to new file
        outfile = tempname() * ".fgb"
        FlatGeobuf.write(outfile, fgb)

        # Read back
        fgb2 = FlatGeobuf.read(outfile)
        roundtrip_features = collect(fgb2)

        # Compare
        @test length(roundtrip_features) == length(original_features)
        @test fgb2.header.name == fgb.header.name
        @test fgb2.header.geometry_type == fgb.header.geometry_type
        @test length(fgb2.header.columns) == length(fgb.header.columns)

        # Compare first feature geometry
        @test original_features[1].geometry == roundtrip_features[1].geometry

        # Compare properties
        for i in 1:min(5, length(original_features))
            orig_props = FlatGeobuf.split_properties(original_features[i].properties, original_features[i].columns)
            rt_props = FlatGeobuf.split_properties(roundtrip_features[i].properties, roundtrip_features[i].columns)
            @test orig_props == rt_props
        end

        # Clean up
        rm(outfile)
    end

    @testset "Write with missing values" begin
        # Test file with null values
        fgb = FlatGeobuf.read(joinpath(@__DIR__, "null.fgb"))
        original_features = collect(fgb)

        outfile = tempname() * ".fgb"
        FlatGeobuf.write(outfile, fgb)

        fgb2 = FlatGeobuf.read(outfile)
        roundtrip_features = collect(fgb2)

        @test length(roundtrip_features) == length(original_features)

        # Verify missing values are preserved
        t_orig = DataFrame(FlatGeobuf.read(joinpath(@__DIR__, "null.fgb")))
        t_rt = DataFrame(fgb2)
        @test ismissing(t_rt.date[2]) == ismissing(t_orig.date[2])
        @test ismissing(t_rt.name[2]) == ismissing(t_orig.name[2])

        rm(outfile)
    end

    @testset "Write from DataFrame with GeoInterface geometries" begin
        # Create a simple DataFrame with point geometries
        # Using FlatGeobuf's own Geometry type which implements GeoInterface
        geom1 = FlatGeobuf.Geometry(xy=[1.0, 2.0], type=FlatGeobuf.GeometryTypePoint)
        geom2 = FlatGeobuf.Geometry(xy=[3.0, 4.0], type=FlatGeobuf.GeometryTypePoint)
        geom3 = FlatGeobuf.Geometry(xy=[5.0, 6.0], type=FlatGeobuf.GeometryTypePoint)

        df = DataFrame(
            name = ["A", "B", "C"],
            value = [1.0, 2.0, 3.0],
            geometry = [geom1, geom2, geom3]
        )

        outfile = tempname() * ".fgb"
        FlatGeobuf.write(outfile, df)

        # Read back and verify
        fgb = FlatGeobuf.read(outfile)
        @test length(fgb) == 3
        @test fgb.header.geometry_type == FlatGeobuf.GeometryTypePoint

        features = collect(fgb)
        @test features[1].geometry.xy == [1.0, 2.0]
        @test features[2].geometry.xy == [3.0, 4.0]
        @test features[3].geometry.xy == [5.0, 6.0]

        # Check properties
        df_rt = DataFrame(fgb)
        @test df_rt.name == ["A", "B", "C"]
        @test df_rt.value == [1.0, 2.0, 3.0]

        rm(outfile)
    end

    @testset "Write polygon geometries" begin
        # Create a polygon (triangle)
        poly = FlatGeobuf.Geometry(
            xy=[0.0, 0.0, 1.0, 0.0, 0.5, 1.0, 0.0, 0.0],
            ends=UInt32[4],
            type=FlatGeobuf.GeometryTypePolygon
        )

        df = DataFrame(
            id = [1],
            geometry = [poly]
        )

        outfile = tempname() * ".fgb"
        FlatGeobuf.write(outfile, df)

        fgb = FlatGeobuf.read(outfile)
        @test length(fgb) == 1
        @test fgb.header.geometry_type == FlatGeobuf.GeometryTypePolygon

        features = collect(fgb)
        @test features[1].geometry.xy == [0.0, 0.0, 1.0, 0.0, 0.5, 1.0, 0.0, 0.0]
        @test features[1].geometry.ends == UInt32[4]

        rm(outfile)
    end

    @testset "GeoInterface geometry conversion" begin
        # Test that we can convert existing FlatGeobuf geometries
        # (which implement GeoInterface) through our conversion functions
        fgb = FlatGeobuf.read(fna)
        features = collect(fgb)

        # Convert MultiPolygon and back
        orig_geom = features[1].geometry
        converted = FlatGeobuf.convert_geometry(orig_geom)

        @test converted.type == orig_geom.type
        # For MultiPolygon, parts should match
        @test length(converted.parts) == length(orig_geom.parts)
    end

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
    end
end
