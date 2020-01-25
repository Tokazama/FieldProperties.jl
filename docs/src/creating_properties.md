# Creating Properties

## Components of a property

<p style="font-size:1.5em; text-align:center">
<span>Property</span>
{<span style="color:#2196f3">name</span>} ::
<span style="color:#3f51b5">Type</span> =
<span style="color:#f44336">default value</span>
</p>

* Property :
* {<span style="color:#2196f3">name</span>} :
* ::<span style="color:#3f51b5">Type</span> :
* <span style="color:#f44336">default value</span> :


## Examples

Properties can be defined with varying degrees of specificity.
```julia
julia> @defprop Property1{:prop1}

# name of property. When structure has Property1 assigned to it, it can be retreived using `x.prop1`
julia> propname(prop1)
:prop1

# no default value for Property1
julia> propdefault(prop1)
NotProperty

# no type restriction for Property1
julia> proptype(prop1)
Any
```

Define a property's type
```julia
julia> @defprop Property2{:prop2}::Int

julia> propname(prop2) == :prop2
true

julia> propdefault(prop2) == NotProperty
true

julia> proptype(prop2) == Int
true
```

Define type requirement and default value.
```julia
julia> @defprop Property3{:prop3}::Int=1

julia> propname(prop3) == :prop3
true

julia> propdefault(prop3) == 1
true

julia> proptype(prop3) == Int
true
```

Define a default value but no type requirement.
```julia
julia> @defprop Property4{:prop4}=1

julia> propname(prop4) == :prop4
true

julia> propdefault(prop4) == 1
true

julia> proptype(prop4) == Any
true
```

It's also possible to specify the type and default using anonymous functions.
```julia

julia> @defprop Property5{:prop5}::(x -> eltype(x))=(x -> one(eltype(x)))
```


