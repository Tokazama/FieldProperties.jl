# MetadataUtils.jl

## Goals

ImageProperties is aimed at improving  properties in the `JuliaImage` ecosystem. Although this is currently aimed at integration with `ImageMetadata` the code here could easily be lifted and placed in most other structures to provide similar functionality. I've tried to consider these goals while creating this:

1. Extensibility: Easy for developers to add new properties while using those previously defined
2. Usability: It shouldn't make it harder for users to access or interact with properties.
3. Optimization: It should be possible to optimize performance of accessing and setting properties without violating the first 2 goals.


## Usage

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

# formal getter method for Property1
julia> Property1.getter
prop1 (generic function with 1 method)

# formal setter method for Property1
julia> Property1.setter
prop1! (generic function with 1 method)
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

julia> Property2.getter == prop2
true

julia> Property2.setter == prop2!
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

julia> Property3.getter == prop3
true

julia> Property3.setter == prop3!
true
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

julia> Property4.getter == prop4
true

julia> Property4.setter == prop4!
true
```
