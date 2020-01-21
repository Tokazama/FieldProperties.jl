
"Setter - Type indicating that an instance of an `AbstractProperty` sets a properties."
struct Setter end

"Getter - Type indicating that an instance of an `AbstractProperty` is a retreives properties."
struct Getter end

"""
    AbstractProperty{name}

A `AbstractProperty` serves as a common reference point for accessing methods related to `name`,
where `name` is the dot accessed field (as in `x.<name>`).

See [`@defprop`](@ref), [`@assignprops`](@ref)
"""
abstract type AbstractProperty{name,T} <: Function end

Base.propertynames(::AbstractProperty) = (:getter, :setter)

Base.show(io::IO, p::AbstractProperty) = _show_property(io, p)
Base.show(io::IO, ::MIME"text/plain", p::AbstractProperty) = _show_property(io, p)

function _show_property(io, p::AbstractProperty{name,Getter}) where {name}
    nms = length(methods(p).ms)
    if nms == 1
        print(io, "$(propname(p)) (generic function with 1 method)")
    else
        print(io, "$(propname(p)) (generic function with $nms method)")
    end
end
function _show_property(io, p::AbstractProperty{name,Setter}) where {name}
    nms = length(methods(p).ms)
    if nms == 1
        print(io, "$(name)! (generic function with 1 method)")
    else
        print(io, "$(name)! (generic function with $nms method)")
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
proptype(p::AbstractProperty) = proptype(typeof(p), not_property)
proptype(p::AbstractProperty, context) = proptype(typeof(p), context)
proptype(::Type{<:AbstractProperty}, context) = Any

"""
    propdoc(x)

Returns documentation for property `x`.
"""
propdoc(::T) where {T} = propdoc(T)
propdoc(::Type{P}) where {P<:AbstractProperty} = _extract_doc(Base.Docs.doc(P))
function propdoc(::Type{T}) where {T}
    pnames = assigned_properties(T)
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
propconvert(p::AbstractProperty, v) = propconvert(p, propnam(p), v)
propconvert(p::AbstractProperty, v, x) = propconvert(p, prop2field(x, p), v, x)
propconvert(p, s, v) = _propconvert(p, s, v, proptype(p))
propconvert(p, s, v, x) = _propconvert(p, s, v, proptype(p, x))
_propconvert(p, s, v::V, ::Type{T}) where {T,V<:T} = v
_propconvert(p, s, v::V, ::Type{T}) where {T,V} = convert(T, v)

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
    sym2optional(x, sym)

Search the optional properties of `x` for `sym` and returns the corresponding
property if successful. If no corresponding property is found then `NotProperty`
is returned.
"""
sym2optional(::T, s::Symbol) where {T} = sym2optional(T, s)
function sym2optional(::Type{T}, s::Symbol) where {T}
    for op in optional_properties(T)
        propname(op) === s && return op
    end
    return not_property
end

"NotProperty - Indicates the absence of a property."
@defprop NotProperty{:not_property}
