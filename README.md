# FlatGeobuf.jl
flatgeobuf implementation (https://bjornharrtell.github.io/flatgeobuf/) in Julia.

Very much a *work in progress*.

# Installation
```julia
] add FlatGeobuf
```

# Usage
```julia
import FlatGeobuf; const FGB=FlatGeobuf

feature = FGB.read_file("countries.fgb")
```

# TODO
* Make a root type
* Parse properties of features
* Table interface
* Write support

# Updating the Schema
Good autogeneration from schema is broken as of now. Probably needs waiting on a 1.6/1.7 Julia release so https://github.com/JuliaLang/julia/pull/32658 is merged, so an official flatbuffer implementation can be made over at https://github.com/google/flatbuffers/pull/5088.
