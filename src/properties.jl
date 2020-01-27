"""
    AbstractProperty{name}

A `AbstractProperty` serves as a common reference point for accessing methods related to `name`,
where `name` is the dot accessed field (as in `x.<name>`).

See [`@defprop`](@ref), [`@assignprops`](@ref)
"""
abstract type AbstractProperty{name,T} <: Function end

"NotProperty - Indicates the absence of a property."
struct NotProperty <: AbstractProperty{:not_property,nothing} end
const not_property = NotProperty()
(::NotProperty)(x, s) = error("type $(typeof(x).name) does not have property $s")


is_not_property(x) = x === not_property

Base.show(io::IO, p::AbstractProperty) = _show_property(io, p)
Base.show(io::IO, ::MIME"text/plain", p::AbstractProperty) = _show_property(io, p)

_fxnname(p::AbstractProperty{name,setproperty!}) where {name} = Symbol(name, :!)
_fxnname(p::AbstractProperty{name,getproperty}) where {name} = name
_fxnname(p::AbstractProperty{name,nothing}) where {name} = name
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

get_setter(p::AbstractProperty) = p(setproperty!)

get_getter(p::AbstractProperty) = p(getproperty)

"""
    propname(::AbstractProperty) -> Symbol

Returns the symbolic name of a property.
"""
propname(::P) where {P} = propname(P)
propname(::Type{<:AbstractProperty{name}}) where {name} = name

"""
    prop2field(x, p) -> Symbol

Given the `x` and property `p` returns the symbol corresponding to the field
where the property is stored in `x`. If no corresponding symbol is found then
`nothing` is returned.
"""
prop2field(::T, p::AbstractProperty) where {T} = prop2field(T, p)
prop2field(::Type{T}, ::AbstractProperty) where {T} = nothing

"""
    sym2prop(x, sym) -> AbstractProperty

Given the `x` and symbol `sym` returns the corresponding property. If no
corresponding property is found then `NotProperty` is returned.
"""
sym2prop(::T, s::Symbol) where {T} = sym2prop(T, s)
sym2prop(::Type{T}, s::Symbol) where {T} = not_property

"""
    assigned_fields(x) -> Tuple{Vararg{Symbol}}

Returns the fields labeled as with any property except `NestedProperty` using
`@assignprops`. 
"""
assigned_fields(::T) where {T} = assigned_fields(T)
assigned_fields(::Type{T}) where {T} = ()

@inline function _propertynames(x)
    Base.@_inline_meta
    if has_nested_fields(x)
        if has_dictextension(x)
            return (public_fields(x)...,
                    assigned_fields(x)...,
                    nested_propertynames(x)...,
                    keys(dictextension(x))...)
        else
            return (public_fields(x)...,
                    assigned_fields(x)...,
                    nested_propertynames(x)...)
        end
    else
        if has_dictextension(x)
            return (public_fields(x)...,
                    assigned_fields(x)...,
                    keys(dictextension(x))...)
        else
            return (public_fields(x)..., assigned_fields(x)...)
        end
    end
end

@inline nested_propertynames(x) = _nested_propertynames(x, nested_fields(x))
function _nested_propertynames(x, fields::Tuple)
    return (propertynames(getfield(x, first(fields)))..., _nested_propertynames(x, Base.tail(fields))...)
end
_nested_propertynames(x, fields::Tuple{Symbol}) = propertynames(getfield(x, first(fields)))


function nproperties(x)
    Base.@_inline_meta
    return length(propertynames(x))
end

# this helps use generic code everywhere else when we could be using a property
# or propertyname
_propname(p::Symbol) = p
_propname(p::AbstractProperty) = propname(p)

_iseq(p1, p2) = _propname(p1) === _propname(p2)

function _iterate_properties(x, i=1)
    Base.@_inline_meta
    i > nproperties(x) && return nothing
    p = @inbounds(propertynames(x)[i])
    return (p => getproperty(x, p), i + 1)
end
