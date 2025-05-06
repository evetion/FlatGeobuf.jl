using GeoInterface
using Extents
using GeoFormatTypes

GeoInterface.isfeaturecollection(::Type{FlatGeobuffer}) = true
GeoInterface.trait(::FlatGeobuffer) = GeoInterface.FeatureCollectionTrait()
GeoInterface.getfeature(::GeoInterface.FeatureCollectionTrait, fgb::FlatGeobuffer, i) = fgb[i]
GeoInterface.nfeature(::GeoInterface.FeatureCollectionTrait, fgb::FlatGeobuffer) = fgb.header.features_count
GeoInterface.ncoord(::GeoInterface.FeatureCollectionTrait, fgb::FlatGeobuffer) = 2 + fgb.header.has_z + fgb.header.has_m
GeoInterface.geometrycolumns(fgb::FlatGeobuffer) = (:geometry,)
function GeoInterface.crs(fgb::FlatGeobuffer)
    crs = fgb.header.crs
    if crs.code != 0
        return GeoFormatTypes.EPSG(crs.code)
    elseif !isempty(crs.wkt)
        return GeoFormatTypes.WKT(crs.wkt)
    else
        return nothing
    end
end

GeoInterface.isfeature(::Type{Feature}) = true
GeoInterface.trait(::Feature) = GeoInterface.FeatureTrait()
GeoInterface.geometry(f::Feature) = f.geometry
GeoInterface.properties(f::Feature) = split_properties(f.properties, f.columns)

GeoInterface.isgeometry(::Type{Geometry}) = true
GeoInterface.ncoord(::GeoInterface.AbstractTrait, geom::Geometry) = 2 + !isempty(geom.z) + !isempty(geom.m)
GeoInterface.geomtrait(geom::Geometry) = _geomtrait(geom.type)
GeoInterface.geomtrait(fgb::FlatGeobuffer) = _geomtrait(fgb.header.geometry_type)
function _geomtrait(type::GeometryType)
    if type == GeometryTypePoint
        return GeoInterface.PointTrait()
    elseif type == GeometryTypeLineString
        return GeoInterface.LineStringTrait()
    elseif type == GeometryTypePolygon
        return GeoInterface.PolygonTrait()
    elseif type == GeometryTypeMultiPoint
        return GeoInterface.MultiPointTrait()
    elseif type == GeometryTypeMultiLineString
        return GeoInterface.MultiLineStringTrait()
    elseif type == GeometryTypeMultiPolygon
        return GeoInterface.MultiPolygonTrait()
    elseif type == GeometryTypeGeometryCollection
        return GeoInterface.GeometryCollectionTrait()
    elseif type == GeometryTypeCircularString
        return GeoInterface.CircularStringTrait()
    elseif type == GeometryTypeCompoundCurve
        return GeoInterface.CompoundCurveTrait()
    elseif type == GeometryTypeCurvePolygon
        return GeoInterface.CurvePolygonTrait()
    elseif type == GeometryTypeMultiCurve
        return GeoInterface.MultiCurveTrait()
    elseif type == GeometryTypeMultiSurface
        return GeoInterface.MultiSurfaceTrait()
    elseif type == GeometryTypeCurve
        return GeoInterface.AbstractCurveTrait()
    elseif type == GeometryTypeSurface
        return GeoInterface.AbstractSurfaceTrait()
    elseif type == GeometryTypePolyhedralSurface
        return GeoInterface.PolyhedralSurfaceTrait()
    elseif type == GeometryTypeTIN
        return GeoInterface.TINTrait()
    elseif type == GeometryTypeTriangle
        return GeoInterface.TriangleTrait()
    else
        return nothing
    end
end

function GeoInterface.ngeom(::GeoInterface.AbstractTrait, geom::Geometry)
    if !isempty(geom.parts)
        return length(geom.parts)
    elseif !isempty(geom.ends)
        return length(geom.ends)
    else
        return 1
    end
end

function GeoInterface.getgeom(::GeoInterface.AbstractTrait, geom::Geometry, i::Integer)
    # Collection
    if !isempty(geom.parts)
        return geom.parts[i]
    end

    # Multi
    if !isempty(geom.ends)
        i = i == 1 ? 1 : geom.ends[i-1]
        j = geom.ends[i]
        # Single
    elseif i == 1
        i = 1
        j = length(geom.xy)
    else
        throw(BoundsError(geom, i))
    end
    Geometry(
        ends=isempty(geom.ends) ? UInt32[] : UInt32[i:j],
        xy=isempty(geom.xy) ? Float64[] : geom.xy[i:j],
        z=isempty(geom.z) ? Float64[] : geom.z[i:j],
        m=isempty(geom.m) ? Float64[] : geom.m[i:j],
        t=isempty(geom.t) ? Float64[] : geom.t[i:j],
        tm=isempty(geom.tm) ? UInt64[] : geom.tm[i:j],
        type=childtype(geom.type),
        parts=Geometry[]
    )
end

GeoInterface.ngeom(::GeoInterface.AbstractLineStringTrait, geom::Geometry) = length(geom.xy) ÷ 2
function GeoInterface.getgeom(::GeoInterface.AbstractLineStringTrait, geom::Geometry, i::Integer)
    Geometry(
        ends=isempty(geom.ends) ? UInt32[] : UInt32[i:i],
        xy=isempty(geom.xy) ? Float64[] : geom.xy[(i*2)-1:(i*2)],
        z=isempty(geom.z) ? Float64[] : geom.z[i:i],
        m=isempty(geom.m) ? Float64[] : geom.m[i:i],
        t=isempty(geom.t) ? Float64[] : geom.t[i:i],
        tm=isempty(geom.tm) ? UInt64[] : geom.tm[i:i],
        type=childtype(geom.type),
        parts=Geometry[]
    )
end

function GeoInterface.getcoord(::GeoInterface.PointTrait, geom::Geometry, i)
    if i == 1
        geom.xy[1]
    elseif i == 2
        geom.xy[2]
    elseif i == 3 && !isempty(geom.z)
        geom.z[1]
    elseif i == 4 && !isempty(geom.m)
        geom.m[1]
    else
        throw(BoundsError(geom, i))
    end
end
