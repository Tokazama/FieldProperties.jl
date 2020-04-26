
"""
    AbstractProperty{name}

A `AbstractProperty` serves as a common reference point for accessing methods related to `name`,
where `name` is the dot accessed field (as in `x.<name>`).

See [`@defprop`](@ref), [`@properties`](@ref)
"""
abstract type AbstractProperty{name,T} <: Function end

#NotProperty - Indicates the absence of a property.
struct NotProperty <: AbstractProperty{:not_property,nothing} end
const not_property = NotProperty()

Base.show(io::IO, p::AbstractProperty) = _show_property(io, p)
Base.show(io::IO, ::MIME"text/plain", p::AbstractProperty) = _show_property(io, p)

_fxnname(p::AbstractProperty{name,setproperty!}) where {name} = Symbol(name, :!)
_fxnname(p::AbstractProperty{name,getproperty}) where {name} = name
_fxnname(p::AbstractProperty{name,fxn}) where {name,fxn} = "$name($fxn)"

function _show_property(io, p::AbstractProperty)
    return __show_property(io, _fxnname(p), length(methods(p)))
end

function __show_property(io, fxnname, nmethods)
    if nmethods == 1
        print(io, "$fxnname (generic function with 1 method)")
    else
        print(io, "$fxnname (generic function with $nmethods methods)")
    end
end


function (p::AbstractProperty{name,getproperty})(x) where {name}
    return propconvert(p, x, getproperty(x, name))
end

function (p::AbstractProperty{name,setproperty!})(x, val) where {name}
    return setproperty!(x, name, propconvert(p, x, val))
end

(p::AbstractProperty{name,eltype})(x) where {name} = Any

"""
    propconvert(p, context, v)

Ensures the value `v` is the appropriate type for property `p` given `context`.
If `v` isn't the appropriate type then `propconvert` attempts to convert to the
"correct type".

"""
@inline propconvert(p, x, v) = _propconvert(p(eltype)(x), v)
_propconvert(::Type{T}, v::V) where {T,V<:T} = v
_propconvert(::Type{T}, v::V) where {T,V} = T(v)::T

