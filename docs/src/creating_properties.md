## Creating Properties

Properties can be defined with varying degrees of specificity.
```julia
julia> @defprop Property1{:prop1}

# name of property. When structure has Property1 assigned to it, it can be retreived using `x.prop1`
julia> propname(Property1)
:prop1

# no default value for Property1
julia> propdefault(Property1)
NotProperty

# no type restriction for Property1
julia> proptype(Property1)
Any
```

Define a property's type
```julia
julia> @defprop Property2{:prop2}::Int

julia> propname(Property2) == :prop2
true

julia> propdefault(Property2) == NotProperty
true

julia> proptype(Property2) == Int
true
```

Define type requirement and default value.
```julia
julia> @defprop Property3{:prop3}::Int=1

julia> propname(Property3) == :prop3
true

julia> propdefault(Property3) == 1
true

julia> proptype(Property3) == Int
true
p
```

Define a default value but no type requirement.
```julia
julia> @defprop Property4{:prop4}=1

julia> propname(Property4) == :prop4
true

julia> propdefault(Property4) == 1
true

julia> proptype(Property4) == Any
true
```

## Changing A Property's Behavior

If a previously defined property (e.g, `prop3` from above) needs a different type or default output, we can just create unique `proptype` and `propdefault` methods.

```julia

julia> struct MyStruct end

julia> FieldProperties.proptype(::Type{<:Property3}, ::Type{<:MyStruct}) = String

julia> FieldProperties.propdefault(::Type{<:Property3}, ::Type{<:MyStruct}) = ""

```

