using Tables

const lookup = Dict(
        ColumnTypeByte => Int8,
        ColumnTypeUByte => UInt8,
        ColumnTypeBool => Bool,
        ColumnTypeShort => Int16,
        ColumnTypeUShort => UInt16,
        ColumnTypeInt => Int32,
        ColumnTypeUInt => UInt32,
        ColumnTypeLong => Int64,
        ColumnTypeULong => UInt64,
        ColumnTypeFloat => Float32,
        ColumnTypeDouble => Float64,
        ColumnTypeString => String,
        ColumnTypeJson => String,
        ColumnTypeDateTime => String,
        ColumnTypeBinary => String
    )


Tables.istable(::Type{<:FlatGeobuffer}) = true
Tables.rowaccess(::Type{<:FlatGeobuffer}) = true
Tables.rows(fgb::FlatGeobuffer) = fgb
Tables.schema(fgb::FlatGeobuffer) = Tables.Schema((map(c -> Symbol(c.name), fgb.header.columns)..., :geom), (map(c -> lookup[c.type], fgb.header.columns)..., Geometry))
