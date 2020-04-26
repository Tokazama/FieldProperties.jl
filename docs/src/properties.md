# Properties

## What are properties?
The term properties in this package originates from how it is used in base Julia (`propertynames`, `getproperty`, `setproperty!`). Each of these methods is covered in detail in the Julia's documentation, so here we focus only on a few key points.

* "Properties" are accessed via the dot operator.
* "Fields" are the explicit names used in the definition of a structure.
* The default properties of an instance of a structure are its fields.
* Fields can _ALWAYS_ be accessed using `getfield` and `setfield!`
```julia
julia> struct SomeType
           field  # this is a field
       end


julia> x = SomeType(1)
SomeType(1)

# dot operator used as syntactic sugar for getproperty which then calls getfield
julia> x.field == getproperty(x, :field) == getfield(x, :field)
true

julia> Base.getproperty(x::SomeType, p::Symbol) = p === :property ? getfield(x, :field) : error("$p is not a property of SomeType")

# "field" is no longer a property of SomeType
julia> x.field
ERROR: field is not a property of SomeType
[...]

# "field" is still considered a field of SomeType but the only property is "property" now
julia> x.property == getproperty(x, :property) == getfield(x, :field)
true
```

## Creating Properties

When a dot operator call `getproperty` or `setproperty!` it represent the property as a `Symbol`. Sometimes it's useful to have a method that retrieves a specific property so that users have a common API that doesn't change despite changes in the internal structure of types. `@defprop` automatically creates a method that calls `getproperty` and a method that calls `setproperty!`. This permits a sort of duck typing that can also be optimized for compile time performance. This section describes how to create properties quickly and some ways of customizing the behavior.

## Assigning Properties

`@properties` makes it easy to create new properties for a given type. Conceptually, it allows one to create a type structure that has fields focused on efficient design and then provide a user facing set of properties to access them. It may be useful to define a set of methods using `@defprop` and then assign the relevant fields to a custom structure.
