## Introduction

Herein the term "properties" is used to refer to any single piece of data that is stored within another structure and "metadata" refers to the entire collection of properties that belongs to a structure. Some additional characteristics of properties (according to the definition used in this package) are:

* They are not necessarily known at compile time (much like the elements of an array or values in a dictionary)
* They carry semantic meaning that may be shared across structures (similar to `eltype` or `ndims` for arrays)
* They may have different characteristic in different contexts (mutable/immutable in certain structures or even optionally defined)

This package was created while trying to balance the following goals:

1. Extensibility: Easy for developers to add new properties while using those previously defined
2. Usability: It shouldn't make it harder for users to access or interact with properties.
3. Optimization: It should be possible to optimize performance of accessing and setting properties without violating the first 2 goals.


[ImageMetadata.jl](https://github.com/JuliaImages/ImageMetadata.jl), [MetadataArrays.jl](https://github.com/piever/MetadataArrays.jl), and [MetaGraph.jl](https://github.com/JuliaGraphs/MetaGraphs.jl) are just a few packages that provide a way of adding metadata to array or graph structures. [FieldMetadata.jl](https://github.com/rafaqz/FieldMetadata.jl) allows creating methods that produce "metadata" at each field of a structure. These packages provide similar functionality but have little overlap in the core functionality used here. Therefore, this package may be seen as complementary to these.

There are some packages that have significant overlap with FieldProperties. [MacroTools.jl](https://github.com/MikeInnes/MacroTools.jl) provides `@forward` which conveniently maps method definitions to specific fields of structures. This overlaps with a great deal of what `@properties` does. However, `@forward` is strictly for methods (not properties) and there are some [benefits](#creating-structures-that-contain-properties) to using `@properties`. There are many packages aimed at metaprogramming that appear to have very similar utilities. However, FieldProperties was created because none of them appeared to accomplish all the previously mentioned goals and there wasn't a clear path forward in using them together to accomplish those goals.

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
