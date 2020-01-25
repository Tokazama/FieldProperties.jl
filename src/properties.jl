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

get_setter(::P) where {P<:AbstractProperty} = get_setter(P)

get_getter(::P) where {P<:AbstractProperty} = get_getter(P)

"""
    propname(::AbstractProperty) -> Symbol

Returns the symbolic name of a property.
"""
propname(::P) where {P} = propname(P)
propname(::Type{<:AbstractProperty{name}}) where {name} = name

"""
    propdefault(property, context)
"""
propdefault(p::AbstractProperty) = propdefault(p, not_property)
propdefault(::Type{P}) where {P<:AbstractProperty} = propdefault(P, not_property)
propdefault(p::AbstractProperty, context) = propdefault(typeof(p), context)
propdefault(::Type{<:AbstractProperty}, context) = not_property

"""
    proptype(p[, context]) -> Type

Return the appropriate type for property `p` given `context`. This method allows
unique type restrictions given different types for `context`.
"""
proptype(p::AbstractProperty) = proptype(typeof(p))
proptype(::Type{P}) where {P<:AbstractProperty} = proptype(P, not_property)
proptype(p::AbstractProperty, context) = proptype(typeof(p), context)
proptype(::Type{<:AbstractProperty}, context) = Any

"""
    propdoc(x)

Returns documentation for property `x`.
"""
propdoc(::T) where {T} = propdoc(T)
propdoc(::Type{P}) where {P<:AbstractProperty} = _extract_doc(Base.Docs.doc(P))
function propdoc(::Type{T}) where {T}
    pnames = assigned_fields(T)
    return NamedTuple{pnames}(([propdoc(sym2prop(T, p)) for p in pnames]...,))
end

_extract_doc(x::Markdown.MD) = _extract_doc(x.content)
_extract_doc(x::AbstractArray) = isempty(x) ? "" : _extract_doc(first(x))
_extract_doc(x::Markdown.Paragraph) = _extract_doc(x.content)
_extract_doc(x::String) = x

"""
    propconvert(p, v[, context])
    propconvert(p, s, v[, context])

Ensures the `v` is the appropriate type for property `p` given `x`. If it isn't
then `propconvert` attempts to convert to the "correct type". The "correct type"
is determined by `proptype(p, x)`.
"""
propconvert(p::AbstractProperty, v) = propconvert(p, propname(p), v)
propconvert(p::AbstractProperty, s, v) = _propconvert(p, s, v, proptype(p))
propconvert(p::AbstractProperty, s, v, x) = _propconvert(p, s, v, proptype(p, x))
_propconvert(p::AbstractProperty, s, v::V, ::Type{T}) where {T,V<:T} = v
_propconvert(p::AbstractProperty, s, v::V, ::Type{T}) where {T,V} = convert(T, v)

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


# this helps use generic code everywhere else when we could be using a property
# or propertyname
_propname(p::Symbol) = p
_propname(p::AbstractProperty) = propname(p)

_iseq(p1, p2) = _propname(p1) === _propname(p2)

