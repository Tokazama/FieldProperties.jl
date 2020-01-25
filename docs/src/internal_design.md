# Internals Design

The fully defined property `@defprop PropertyType{:prop}::T=D` has 4 components
* `PropertyType`: conrete subtype of `AbstractProperty`
* `:prop`: the properties symbolic name
* `T`: The type restriction that ensures that a retrieved property is either convert to are already is `<:T`. `T` may be alternatively replaced with an anonymous function.
* `D`: The default type. `D` may also be replaced with an anonymous function.

The previous example is equivalent to:
```julia
struct PropertyType{T} <: AbstractProperty{:prop,T} end

# getter function
const prop = PropertyType{Getter}()

# setter function
const prop! = PropertyType{Setter}()

FieldProperties.get_setter(::Type{<:PropertyType}) = prop!

FieldProperties.get_getter(::Type{<:PropertyType}) = prop

FieldProperties.propdefault(::Type{<:PropertyType}, x) = D

FieldProperties.proptype(::Type{<:PropertyType}, x) = T
```

If instead anonymous functions are used to define the type and default such as, `@defprop PropertyType{:prop}::(y -> eltype(y))= y -> maximum(y)` then the last two methods are defined as:
```julia

FieldProperties.propdefault(::Type{<:PropertyType}, y) = maximum(y)

FieldProperties.proptype(::Type{<:PropertyType}, y) = eltype(y)
```
Note that the variable passed to the anonmyous function are captured in the creation of the the new method. if `x -> eltype(y)` was used there would be an error when trying to use `proptype`.
