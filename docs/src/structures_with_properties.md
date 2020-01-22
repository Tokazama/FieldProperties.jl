## Creating Structures That Contain Properties

Although properties can be used flexibly with different structures, it may be easier to take advantage of the provided `AbstractMetadata` type. In the following example we take advantage of the `Description` and `DictExtension`. These provide a method of describing a structure and an extensible pool for storing an arbitrary number of properties.

```julia
julia> mutable struct MyProperties{M} <: AbstractMetadata{M}
           my_description::String
           my_properties::M
       end

# tells other functions where to find the dictionary so there's support for dictionary methods
julia> FieldProperties.subdict(m::MyProperties) = getfield(m, :my_properties)
```

Binding `Description` and `DictExtension` to specific fields is accomplished through `@assignprops`. Several other methods specific to `MyProperties` are created to provide property like behavior. Most notably, the methods from base overwritten are `getproperty`, `setproperty!`, and `propertynames`.
```julia
julia> @assignprops(
           MyProperties,
           :my_description => description,
           :my_properties => dictextension)

julia> m = MyProperties("", Dict{Symbol,Any}())
MyProperties{Dict{Symbol,Any}} with 1 entry
    description:

julia> propertynames(m)
(:description,)
```

```julia
julia> FieldProperties.description(m)
""

julia> FieldProperties.description!(m, "foo")
MyProperties{Dict{Symbol,Any}} with 1 entry
    description: foo

julia> FieldProperties.description(m)
"foo"

julia> m.description = "bar"
"bar"

julia> FieldProperties.description(m)
"bar"

julia> m.description
"bar"
```

Optional properties can be assigned to the `DictExtension` using the `DictExtension(Propert1, Property2)` syntax.
```julia
julia> @defprop CalibrationMaximum{:calmax}

julia> FieldProperties.propdefault(::CalibrationMaximumType, x::AbstractArray) = maximum(x)

julia> FieldProperties.proptype(::CalibrationMaximumType, ::Type{<:AbstractArray{T,N}}) where {T,N} = T

julia> @defprop CalibrationMinimum{:calmin}

julia> FieldProperties.propdefault(::CalibrationMinimumType, x::AbstractArray) = minimum(x)

julia> FieldProperties.proptype(::CalibrationMinimumType, ::Type{<:AbstractArray{T,N}}) where {T,N} = T

julia> struct MyArray{T,N,P<:AbstractArray{T,N},M<:AbstractDict{Symbol,Any}} <: AbstractArray{T,N}
           _parent::P
           my_properties::M
       end

julia> Base.parent(m::MyArray) = getfield(m, :_parent)

julia> Base.size(m::MyArray) = size(parent(m))

julia> Base.maximum(m::MyArray) = maximum(parent(m))

julia> Base.minimum(m::MyArray) = minimum(parent(m))

julia> @assignprops(
           MyArray,
           :my_properties => dictextension(calmax,calmin))
```
