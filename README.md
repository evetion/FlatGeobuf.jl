# FlatGeobuf.jl
A native [flatgeobuf](https://github.com/flatgeobuf/flatgeobuf) implementation in Julia. Flatgeobuf is a cloud optimized geospatial vector format.

# Installation
```julia
] add FlatGeobuf
```

# Usage
```julia
import FlatGeobuf; const FGB=FlatGeobuf

fgb = FGB.read_file("countries.fgb")
FlatGeobuffer with 179 GeometryTypeMultiPolygon features.
```

FlatGeobuf supports the `Tables.jl` interface.
```julia
using DataFrames
DataFrame(fgb)
179×3 DataFrame. Omitted printing of 1 columns
│ Row │ id     │ name                                │
│     │ String │ String                              │
├─────┼────────┼─────────────────────────────────────┤
│ 1   │ ATA    │ Antarctica                          │
│ 2   │ ATF    │ French Southern and Antarctic Lands │
│ 3   │ NAM    │ Namibia                             │
│ 4   │ BWA    │ Botswana                            │
│ 5   │ SWZ    │ Swaziland                           │
│ 6   │ ZAF    │ South Africa                        │
│ 7   │ LSO    │ Lesotho                             │
│ 8   │ MOZ    │ Mozambique                          │
│ 9   │ MWI    │ Malawi                              │
│ 10  │ ZMB    │ Zambia                              │
│ 11  │ ZWE    │ Zimbabwe                            │
│ 12  │ AGO    │ Angola                              │
│ 13  │ COD    │ Democratic Republic of the Congo    │
│ 14  │ RWA    │ Rwanda                              │
```

FlatGeobuffers have a spatial index that we can query with a bounding box
```julia
bbox = [-92.73405699999999, 32.580974999999995, -92.73405699999999, 32.580974999999995]
filter!(fgb, bbox)
julia> DataFrame(fgb)
2×3 DataFrame. Omitted printing of 1 columns
│ Row │ id     │ name                     │
│     │ String │ String                   │
├─────┼────────┼──────────────────────────┤
│ 1   │ MEX    │ Mexico                   │
│ 2   │ USA    │ United States of America │
```

# TODO
* GeoInterface support
* Write support

# Updating the Schema
I've used https://github.com/rjkat/flatbuffers-julia to autogenerate the files found in `src/schema`, but had to adapt them. Good autogeneration from schema is broken as of now. Probably needs waiting on a 1.6/1.7 Julia release so https://github.com/JuliaLang/julia/pull/32658 is merged, so an official flatbuffer implementation can be made over at https://github.com/google/flatbuffers/pull/5088.
