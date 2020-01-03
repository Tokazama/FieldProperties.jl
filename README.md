# ImageProperties.jl


ImageProperties provides dictionaries where the key-value pairs can be accessed
and set like the properties of a structure.

```julia
using ImageProperties, ImageProperties

julia> m = Metadata()
Metadata{Dict{Symbol,Any}} with 0 entries

julia> m[:prop1] = 1
1

julia> m
Metadata{Dict{Symbol,Any}} with 1 entry:
  :prop1 => 1

julia> m.prop2 = 2
2

julia> m
Metadata{Dict{Symbol,Any}} with 2 entries:
  :prop2 => 2
  :prop1 => 1
```

This also provides tab completion.
```julia
julia> m.prop  # <TAB>
prop1 prop2
```

We can improve performance for accessing properites by creating a custom metadata
structure.
```julia

julia> mutable struct SimpleMetadata{D} <: AbstractMetadata{D}
           prop1::Int
           properties::D
       end
```

In order to use the structure we need to do several things:
```julia
# standard interface to the dictionary component
julia> ImageMetadata.properties(m::SimpleMetadata) = getfield(m, :properties)

# pass getproperty arguments to get_property (provided by ImagePropeties)
julia> Base.getproperty(m::SimpleMetadata, s::Symbol) = get_property(m, s)

# pass setproperty! arguments to set_property! (provided by ImagePropeties)
julia> Base.setproperty!(m::SimpleMetadata, s::Symbol, val) = set_property!(m, s, val)

# tell ImageProperties what fields should be considered properties
julia> ImageProperties.struct_properties(::Type{<:SimpleMetadata}) = (:prop1,)
```


Now we can create an instance of `SimpleMetadata`.
```julia
julia> sm = SimpleMetadata(1, Dict{Symbol,Any}())
SimpleMetadata{Dict{Symbol,Any}} with 1 entry
    prop1: 1

julia> sm.prop1 = 2
2

julia> sm
SimpleMetadata{Dict{Symbol,Any}} with 1 entry
    prop1: 2

julia> sm.prop2 = 3
3

julia> sm
SimpleMetadata{Dict{Symbol,Any}} with 2 entries
    prop1: 2
    prop2: 3

julia> @code_typed ((m) -> m.prop1)(sm)
CodeInfo(
1 ─ %1 = ImageProperties.getfield(m, :prop1)::Int64
└──      return %1
) => Int64
```

```julia
julia> img = ImageMeta(rand(4,4), sm)
Float64 ImageMeta with:
  data: 4×4 Array{Float64,2}
  properties:
    prop1: 2
    prop2: 3

julia> @code_typed ((m) -> m.prop1)(img)
CodeInfo(
1 ─ %1 = ImageMetadata.getfield(m, :properties)::SimpleMetadata{Dict{Symbol,Any}}
│   %2 = ImageProperties.getfield(%1, :prop1)::Int64
└──      return %2
) => Int64
```

