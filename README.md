# ImageProperties.jl


ImageProperties provides dictionaries where the key-value pairs can be accessed
and set like the properties of a structure.

```julia
using ImageProperties, ImageCore, ImageMetadata, BenchmarkTools

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

This can be further used as the properties of `ImageMeta`
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

We can extend the functionality of our `SimpleMetadata` type with a new metadata
structure.
```julia
julia> mutable struct Prop2Metadata{D} <: AbstractMetadata{D}
           prop2::Int
           properties::D
       end

julia> ImageMetadata.properties(m::Prop2Metadata) = getfield(m, :properties)

julia> Base.getproperty(m::Prop2Metadata, s::Symbol) = get_property(m, s)

julia> Base.setproperty!(m::Prop2Metadata, s::Symbol, val) = set_property!(m, s, val)

julia> ImageProperties.struct_properties(::Type{<:Prop2Metadata}) = (:prop2,)

julia> sm2 = SimpleMetadata(1, Prop2Metadata(2, Dict{Symbol,Any}()))
SimpleMetadata{Prop2Metadata{Dict{Symbol,Any}}} with 2 entries
    prop1: 1
    prop2: 2
```

By combining the two we add a new property to the original `SimpleMetadata`
without requiring a completely new structure. This makes reusing 
```julia

julia> sm2.prop3 = 3
3

julia> sm2
SimpleMetadata{Prop2Metadata{Dict{Symbol,Any}}} with 3 entries
    prop1: 1
    prop2: 2
    prop3: 3

julia> @code_typed ((m) -> m.prop1)(sm2)
CodeInfo(
1 ─ %1 = ImageProperties.getfield(m, :prop1)::Int64
└──      return %1
) => Int64

julia> @code_typed ((m) -> m.prop2)(sm2)
CodeInfo(
1 ─      goto #3 if not true
2 ─      nothing::Nothing
3 ┄ %3 = Main.getfield(m, :properties)::Prop2Metadata{Dict{Symbol,Any}}
│   %4 = ImageProperties.getfield(%3, :prop2)::Int64
└──      goto #4
4 ─      goto #5
5 ─      return %4
) => Int64

julia> @code_typed ((m) -> m.prop3)(sm2)
CodeInfo(
1 ──       goto #3 if not true
2 ──       nothing::Nothing
3 ┄─ %3  = Main.getfield(m, :properties)::Prop2Metadata{Dict{Symbol,Any}}
└───       goto #5 if not true
4 ──       nothing::Nothing
5 ┄─ %6  = Main.getfield(%3, :properties)::Dict{Symbol,Any}
│    %7  = invoke Base.ht_keyindex(%6::Dict{Symbol,Any}, :prop3::Symbol)::Int64
│    %8  = Base.slt_int(%7, 0)::Bool
└───       goto #7 if not %8
6 ── %10 = Base.KeyError::Type{KeyError}
│    %11 = %new(%10, :prop3)::KeyError
│          Base.throw(%11)::Union{}
└───       $(Expr(:unreachable))::Union{}
7 ┄─ %14 = Base.getfield(%6, :vals)::Array{Any,1}
│    %15 = Base.arrayref(false, %14, %7)::Any
└───       goto #8
8 ──       goto #9
9 ──       goto #10
10 ─       goto #11
11 ─       return %15
) => Any
```

## Improving permutations

A very preliminary structure for enhancing the performance of spatial operations
is the `SpatialProperties` type. It currently only encodes the `spacedirections`
property, but is integrated into an alias for `ImageMeta`, `SpatialImage` (an `ImageMeta`
that uses `SpatialProperties` as its dictionary).
```julia
julia> a = rand(2,2);

julia> img1 = ImageMeta(a, spacedirections=spacedirections(a));

julia> img2 = SpatialImage(a);

julia> @btime spacedirections($img1)
  7.528 ns (0 allocations: 0 bytes)
((1, 0), (0, 1))

julia> @btime spacedirections($img2)
 0.035 ns (0 allocations: 0 bytes)
((1, 0), (0, 1))

julia> @code_typed spacedirections(img1)
CodeInfo(
1 ─ %1  = ImageMetadata.getfield(img@_2, :properties)::Dict{Symbol,Any}
│   %2  = π (:spacedirections, Core.Compiler.Const(:spacedirections, false))
│   %3  = invoke Base.ht_keyindex(%1::Dict{Symbol,Any}, %2::Symbol)::Int64
│   %4  = Base.slt_int(%3, 0)::Bool
└──       goto #3 if not %4
2 ─       goto #4
3 ─ %7  = Base.getfield(%1, :vals)::Array{Any,1}
│   %8  = Base.arrayref(false, %7, %3)::Any
└──       goto #4
4 ┄ %10 = φ (#2 => $(QuoteNode(ImageMetadata.IMNothing())), #3 => %8)::Any
│   %11 = (%10 isa ImageMetadata.IMNothing)::Bool
└──       goto #6 if not %11
5 ─       return ((1, 0), (0, 1))
6 ─       return %10
) => Any

julia> @code_typed spacedirections(img2)
CodeInfo(
1 ─ %1 = ImageMetadata.getfield(img, :properties)::SpatialProperties{Dict{Symbol,Any},Tuple{Tuple{Int64,Int64},Tuple{Int64,Int64}}}
│   %2 = ImageProperties.getfield(%1, :spacedirections)::Tuple{Tuple{Int64,Int64},Tuple{Int64,Int64}}
└──      return %2
) => Tuple{Tuple{Int64,Int64},Tuple{Int64,Int64}}
```
