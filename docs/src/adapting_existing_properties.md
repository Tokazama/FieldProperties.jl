# Changing A Property's Behavior

If a previously defined property needs a different type or default output, we can just create unique `proptype` and `propdefault` methods.

```julia
julia> @defprop Property3{:prop3}::Int=1

julia> struct MyStruct end

julia> FieldProperties.proptype(::Type{<:Property3}, ::Type{<:MyStruct}) = String

julia> FieldProperties.propdefault(::Type{<:Property3}, ::Type{<:MyStruct}) = ""
```

`MyStruct` isn't particularly interesting but it could contain, nested property fields, a dictionary for optional properties, or just fields for `prop3`. In such cases it's common to use something like `prop3(x::MyStruct) = get(x, :prop3, "")` to ensue a dictionary still returns something appropriate. However, this doesn't provide type stability, check nested fields for the property, or automatically convert returned values to the appropriate type.

TODO: more detail
