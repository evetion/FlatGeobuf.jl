using Test
using FlatGeobuf
using FlatBuffers
using Tables
using DataFrames
using Extents
using Downloads
using GeoInterface
using GeoFormatTypes
using Dates
using InlineStrings

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

    @testset "Write" begin
        # Round trip a file
        fgb = FlatGeobuf.read(fna)
        fn = FlatGeobuf.write(tempname() * ".fgb", fgb)
        fgb2 = FlatGeobuf.read(fn)
        @test fgb2.header.geometry_type == FlatGeobuf.GeometryTypeMultiPolygon
        @test fgb2.header.index_node_size == 0
        @test GeoInterface.crs(fgb2) == GeoInterface.crs(fgb) == EPSG(4326)
        df, df2 = DataFrame(fgb), DataFrame(fgb2)
        @test df[!, Not(:geometry)] == df2[!, Not(:geometry)]
        @test GeoInterface.coordinates.(df.geometry) == GeoInterface.coordinates.(df2.geometry)

        # Like GDAL, the size prefixed header and features keep 8-byte alignment
        bytes, pos, aligned = read(fn), 8, true
        while pos < length(bytes)
            pos += 4 + reinterpret(UInt32, bytes[pos+1:pos+4])[1]
            aligned &= pos % 8 == 0
        end
        @test aligned && pos == length(bytes)

        # A file written by GDAL keeps its column types (DateTime is read as String)
        fgb = FlatGeobuf.read(joinpath(@__DIR__, "null.fgb"))
        fgb2 = FlatGeobuf.read(FlatGeobuf.write(tempname() * ".fgb", fgb))
        @test [c.type for c in fgb2.header.columns] == [c.type for c in fgb.header.columns]
        @test isequal(DataFrame(fgb2)[!, Not(:geometry)], DataFrame(fgb)[!, Not(:geometry)])

        # Overwrite the file that is read, and keep it on errors
        fn = cp(fna, tempname() * ".fgb")
        FlatGeobuf.write(fn, FlatGeobuf.read(fn))
        @test length(FlatGeobuf.read(fn)) == 179
        nbytes = filesize(fn)
        @test_throws ArgumentError FlatGeobuf.write(fn, DataFrame(geometry=[GeoInterface.Point(1.0, 2.0), GeoInterface.Point(1.0, 2.0, 3.0)]))
        @test filesize(fn) == nbytes

        # Column types and mixed geometry types
        poly = GeoInterface.Polygon([GeoInterface.LinearRing([(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 0.0)])])
        df = DataFrame(
            int=Int32[1, 2], bool=[true, false], float=[1.5, NaN], string=["ä€", ""], missings=[missing, "x"], inline=String7["ab", "c"],
            date=[Date(2024, 1, 2), Date(2024, 1, 3)], datetime=[DateTime(2024, 1, 2, 3, 4, 5), missing],
            geometry=[poly, GeoInterface.MultiPolygon([poly, poly])],
        )
        fgb = FlatGeobuf.read(FlatGeobuf.write(tempname() * ".fgb", df; crs=EPSG(28992)))
        @test fgb.header.geometry_type == FlatGeobuf.GeometryTypeUnknown
        @test [c.type for c in fgb.header.columns] == [FlatGeobuf.ColumnTypeInt, FlatGeobuf.ColumnTypeBool,
            FlatGeobuf.ColumnTypeDouble, FlatGeobuf.ColumnTypeString, FlatGeobuf.ColumnTypeString,
            FlatGeobuf.ColumnTypeString, FlatGeobuf.ColumnTypeDateTime, FlatGeobuf.ColumnTypeDateTime]
        @test [c.nullable for c in fgb.header.columns] == [false, false, false, false, true, false, false, true]
        @test GeoInterface.crs(fgb) == EPSG(28992)
        df2 = DataFrame(fgb)
        @test isequal(df2[!, 1:6], df[!, 1:6])
        @test df2.date == ["2024-01-02", "2024-01-03"]
        @test isequal(df2.datetime, ["2024-01-02T03:04:05", missing])
        @test GeoInterface.trait.(df2.geometry) == [GeoInterface.PolygonTrait(), GeoInterface.MultiPolygonTrait()]
        @test GeoInterface.coordinates.(df2.geometry) == GeoInterface.coordinates.(df.geometry)

        # Z and M values, collections
        df = DataFrame(geometry=[GeoInterface.Point(1.0, 2.0, 3.0), GeoInterface.LineString([(1.0, 2.0, 3.0), (4.0, 5.0, 6.0)])])
        fgb = FlatGeobuf.read(FlatGeobuf.write(tempname() * ".fgb", df))
        @test fgb.header.has_z && !fgb.header.has_m
        @test GeoInterface.coordinates.(DataFrame(fgb).geometry) == GeoInterface.coordinates.(df.geometry)
        poly = GeoInterface.Polygon([GeoInterface.LinearRing([(0.0, 0.0, 1.0), (1.0, 0.0, 2.0), (1.0, 1.0, 3.0), (0.0, 0.0, 1.0)])])
        fgb = FlatGeobuf.read(FlatGeobuf.write(tempname() * ".fgb", DataFrame(geometry=[GeoInterface.MultiPolygon([poly])])))
        fgb = FlatGeobuf.read(FlatGeobuf.write(tempname() * ".fgb", fgb))  # again, from a FlatGeobuffer
        @test fgb.header.has_z
        @test GeoInterface.coordinates(first(fgb).geometry) == [GeoInterface.coordinates(poly)]
        for (point, coords) in ((GeoInterface.Point((X=1.0, Y=2.0, M=4.0)), [1.0, 2.0, 4.0]), (GeoInterface.Point((X=1.0, Y=2.0, Z=3.0, M=4.0)), [1.0, 2.0, 3.0, 4.0]))
            fgb = FlatGeobuf.read(FlatGeobuf.write(tempname() * ".fgb", DataFrame(geometry=[point])))
            @test fgb.header.has_m
            @test GeoInterface.coordinates(first(fgb).geometry) == coords
        end
        gc = GeoInterface.GeometryCollection([GeoInterface.MultiPoint([(1.0, 2.0)]), GeoInterface.MultiLineString([[(0.0, 0.0), (1.0, 1.0)], [(2.0, 2.0), (3.0, 3.0)]])])
        fgb = FlatGeobuf.read(FlatGeobuf.write(tempname() * ".fgb", DataFrame(geometry=[gc])))
        @test GeoInterface.coordinates(first(fgb).geometry) == GeoInterface.coordinates(gc)

        # Writing to IO
        df = DataFrame(id=[1], geom=[GeoInterface.Point(1.0, 2.0)])
        fn = FlatGeobuf.write(tempname() * ".fgb", df; geometrycolumn=:geom, name="points")
        io = FlatGeobuf.write(IOBuffer(), df; geometrycolumn=(:geom,), name="points")
        @test take!(io) == read(fn)
        @test FlatGeobuf.read(fn).header.name == "points"

        fgb = FlatGeobuf.read(FlatGeobuf.write(tempname() * ".fgb", DataFrame(geometry=GeoInterface.Point[])))
        @test length(fgb) == 0

        # Geometry column and crs from table metadata, as set by GeoDataFrames
        metadata!(df, "GEOINTERFACE:geometrycolumns", (:geom,); style=:note)
        metadata!(df, "GEOINTERFACE:crs", EPSG(4326); style=:note)
        @test GeoInterface.crs(FlatGeobuf.read(FlatGeobuf.write(tempname() * ".fgb", df))) == EPSG(4326)
        wkt = "GEOGCS[\"WGS 84\",DATUM[\"WGS_1984\",SPHEROID[\"WGS 84\",6378137,298.257223563]],PRIMEM[\"Greenwich\",0],UNIT[\"degree\",0.0174532925199433]]"
        fgb = FlatGeobuf.read(FlatGeobuf.write(tempname() * ".fgb", df; crs=WellKnownText(GeoFormatTypes.CRS(), wkt)))
        @test GeoFormatTypes.val(GeoInterface.crs(fgb)) == wkt
        @test_throws ArgumentError FlatGeobuf.write(IOBuffer(), df; crs=ProjJSON("{\"type\": \"GeographicCRS\"}"))

        # Unsupported input
        @test_throws ArgumentError FlatGeobuf.write(IOBuffer(), df; geometrycolumn=:geometry)
        @test_throws ArgumentError FlatGeobuf.write(IOBuffer(), DataFrame(geometry=[missing, GeoInterface.Point(1.0, 2.0)]))
        @test_throws ArgumentError FlatGeobuf.write(IOBuffer(), DataFrame(v=[[1]], geometry=[GeoInterface.Point(1.0, 2.0)]))
        @test_throws ArgumentError FlatGeobuf.write(IOBuffer(), DataFrame(geometry=[GeoInterface.Point(1.0, 2.0), GeoInterface.Point(1.0, 2.0, 3.0)]))
    end
end
