# The `onset` Property

Knowing the onset of some time related event is useful for different analyses, but is encoded within different type structures in a way that may be incompatible for a single universal method. Here we define a property that has default functionality and then build on it for custom types. Throughout this process we try to ensure type stability.

## Defining `onset`

Here we define the `onset` property and assume that if it's called on any subtype of `AbstractArray` that it the first axis refers to the time domain.
```julia
julia> using FieldProperties

julia> @defprop Onset{:onset} begin
           # assume the axis represents time
           @getproperty x::AbstractArray -> first(axes(x, 1))
       end

julia> onset(rand(2,2))
1

julia> @code_warntype (onset(rand(2,2)))
Variables
  #self#::Core.Compiler.Const(onset (generic function with 3 methods), false)
  x::Array{Float64,2}

Body::Int64
1 ─ %1 = Main.axes(x, 1)::Base.OneTo{Int64}
│   %2 = Main.first(%1)::Core.Compiler.Const(1, false)
└──      return %2
```

## Custom Type

Now let's define a very basic type for described an event at a particular time.

```julia
julia> struct TimeEvent
           description::String
           onset::Int
       end

julia> te = TimeEvent("this time event", 2);

julia> onset(te)
2

# equivalent to...
julia> te.onset
2

julia> @code_warntype onset(te)
Variables
  p::Core.Compiler.Const(onset (generic function with 3 methods), false)
  x::TimeEvent

Body::Int64
1 ─ %1 = FieldProperties.getproperty(x, $(Expr(:static_parameter, 1)))::Int64
│   %2 = FieldProperties.propconvert(p, x, %1)::Int64
└──      return %2
```
Notice that we can still access the `onset` field here without any sort of method overloading. We also don't lose type stability. This is because our initial definition of the `onset` property only overloads the `getproperty` version for subtypes of `AbstractArray`. Therefore, the default method is simply `getproperty(x, :onset)`, which is equivalent to `x.onset` for our `TimeEvent` type.

## Optional Presence of `onset`

Now let's use the `Metadata` type to optionally store the `onset` property.
```julia
julia> m = Metadata();

julia> m.onset = 2
2

julia> onset(m)
2

julia> @code_warntype onset(m)
Variables
  p::Core.Compiler.Const(onset (generic function with 3 methods), false)
  x::Metadata{Dict{Symbol,Any}}

Body::Any
1 ─ %1 = FieldProperties.getproperty(x, $(Expr(:static_parameter, 1)))::Any
│   %2 = FieldProperties.propconvert(p, x, %1)::Any
└──      return %2
```

We can overcome problems with type stability by enforcing the returned type through `onset_type` (which was created with our original call to `@defprop`). We also can change the return type using this same method.
```julia
julia> onset_type(m::Metadata) = Float64
onset(eltype) (generic function with 3 methods)

julia> @code_warntype onset(m)
Variables
  p::Core.Compiler.Const(onset (generic function with 3 methods), false)
  x::Metadata{Dict{Symbol,Any}}

Body::Float64
1 ─ %1 = FieldProperties.getproperty(x, $(Expr(:static_parameter, 1)))::Any
│   %2 = FieldProperties.propconvert(p, x, %1)::Float64
└──      return %2

julia> onset(m)
2.0
```
This is functionally similar to writing `onset(m::Metadata) = convert(Float64, getproperty(m, :onset))`.

