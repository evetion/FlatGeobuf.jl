using Tables

lookupd = Dict(
    Gen.ColumnTypeModule.ColumnType.Byte => Int8,
    Gen.ColumnTypeModule.ColumnType.UByte => UInt8,
    Gen.ColumnTypeModule.ColumnType.CBool => Bool,
    Gen.ColumnTypeModule.ColumnType.Short => Int16,
    Gen.ColumnTypeModule.ColumnType.UShort => UInt16,
    Gen.ColumnTypeModule.ColumnType.Int => Int32,
    Gen.ColumnTypeModule.ColumnType.UInt => UInt32,
    Gen.ColumnTypeModule.ColumnType.Long => Int64,
    Gen.ColumnTypeModule.ColumnType.ULong => UInt64,
    Gen.ColumnTypeModule.ColumnType.Float => Float32,
    Gen.ColumnTypeModule.ColumnType.Double => Float64,
    Gen.ColumnTypeModule.ColumnType.CString => String,
    Gen.ColumnTypeModule.ColumnType.Json => String,
    Gen.ColumnTypeModule.ColumnType.DateTime => String,
    Gen.ColumnTypeModule.ColumnType.Binary => String
)
lookup(a) = get(lookupd, a, Nothing)


Tables.istable(::Type{<:FlatGeobuffer}) = true
Tables.rowaccess(::Type{<:FlatGeobuffer}) = true
Tables.rows(fgb::FlatGeobuffer) = fgb
Tables.schema(fgb::FlatGeobuffer) = Tables.Schema((map(c -> Symbol(c.name), fgb.header.columns)..., :geom), (map(x -> x.nullable ? Union{Missing,lookup(x.type)} : lookup(x.type), fgb.header.columns)..., Gen.Geometry))
