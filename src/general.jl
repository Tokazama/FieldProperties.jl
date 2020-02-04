# general properties that just need a home
@defprop Status{:status}

@defprop Modality{:modality}

"""
Property providing label for parent structure.
"""
@defprop Label{:label}::Symbol

"""
    name(x) -> Symbol
    name!(x, val)

Property providing name for parent structure.
"""
@defprop Name{:name}::Symbol

name(::P) where {P<:AbstractProperty} = name(P)
name(::Type{<:AbstractProperty{n}}) where {n} = n

"""
    calmax(x)
    calmax!(x, val)

Specifies maximum element for display purposes. If not specified returns the maximum value in the collection.

## Examples
```jldoctest
julia> using FieldProperties

julia> x = reshape(1:16, 4, 4);

julia> calmax(x)
16

julia> struct ArrayMaxThresh{T,N}
           a::AbstractArray{T,N}
           calmax::T
       end

julia> calmax(ArrayMaxThresh(x, 10))
10
```
"""
@defprop CalibrationMaximum{:calmax}::(x::AbstractArray->eltype(x)) begin
    @getproperty x::AbstractArray -> maximum(x)
end

"""
    calmin(x)
    calmin!(x, val)

Specifies minimum element for display purposes. If not specified returns the minimum value in the collection.

## Examples
```jldoctest
julia> using FieldProperties

julia> x = reshape(1:16, 4, 4);

julia> calmin(x)
1

julia> struct ArrayMinThresh{T,N}
           a::AbstractArray{T,N}
           calmin::T
       end

julia> calmin(ArrayMinThresh(x, 5))
5
```
"""
@defprop CalibrationMinimum{:calmin}::(x::AbstractArray->eltype(x)) begin
    @getproperty x::AbstractArray -> minimum(x)
end

