"""
    Property{name}

A `Property` serves as a common reference point for accessing methods related to `name`,
where `name` is the dot accessed field (as in `x.<name>`).

See [`@defprop`](@ref), [`@assignprops`](@ref)
"""
struct Property{name,G,S} end

Base.propertynames(::Property) = (:getter, :setter)

Base.show(io::IO, p::Property) = _show_property(io, p)
Base.show(io::IO, ::MIME"text/plain", p::Property) = _show_property(io, p)

_show_property(io, ::Property{name}) where {name} = print(io, "Property(:$name)")

function Base.getproperty(p::Property{name,G,S}, s::Symbol) where {name,G,S}
    if s === :setter
        return S
    elseif s === :getter
        return G
    else
        error("type $name has no field $s")
    end
end

"""
    property(x) -> Property

Given a setter or getter function returns the corresponding property.
"""
property(::T) where {T} = property(T)
property(p::Property) = p
property(::Type{T}) where {T} = NotProperty
property(::Type{T}) where {T<:Property} = T()

"""
    propname(::Property) -> Symbol

Returns the symbolic name of a propety.
"""
propname(::P) where {P} = propname(P)
propname(::Type{<:Property{name}}) where {name} = name
# try to catch setters, getters that belong to a property
propname(::Type{P}) where {P<:Function} = _propname(P, property(P))
_propname(::Type{F}, ::Property{:not_property}) where {F<:Function} = Symbol(F.instance)
_propname(::Type{F}, ::Property{name}) where {F<:Function,name} = name

"""
    propdefault(property, context)
"""
propdefault(p::P) where {P} = propdefault(p, NotProperty)
propdefault(p::P, context::C) where {P,C} = propdefault(property(p), C)
propdefault(p::P, context::C) where {P<:Property,C} = propdefault(P, C)
propdefault(p::P, ::Type{C}) where {P,C} = propdefault(property(p), C)
propdefault(p::P, ::Type{C}) where {P<:Property,C} = propdefault(P, C)


"""
    proptype(p[, context]) -> Type

Return the appropriate type for property `p` given `context`. This method allows
unique type restrictions given different types for `context`.
"""
proptype(::P) where {P} = proptype(P, Nothing)
proptype(::P, context::C) where {P,C} = proptype(P, C)
proptype(::P, ::Type{C}) where {P,C} = proptype(P, C)
proptype(::Type{P}, context::C) where {P,C} = proptype(P, C)
proptype(::Type{P}, ::Type{C}) where {P,C} = proptype(property(P), C)
proptype(::Type{P}, ::Type{C}) where {P<:Property,C} = Any

"""
    propconvert(p, v[, context])
    propconvert(p, s, v[, context])

Ensures the `v` is the appropriate type for property `p` given `x`. If it isn't
then `propconvert` attempts to convert to the "correct type". The "correct type"
is determined by `proptype(p, x)`.
"""
propconvert(p::Property, v) = propconvert(x, p, propnam(p), v)
propconvert(p::Property, v, x) = propconvert(x, p, prop2field(x, p), v, x)
propconvert(p, s, v) = _propconvert(p, s, v, proptype(p))
propconvert(p, s, v, x) = _propconvert(p, s, v, proptype(p, x))
_propconvert(p, s, v::V, ::Type{T}) where {T,V<:T} = v
_propconvert(p, s, v::V, ::Type{T}) where {T,V} = convert(T, v)

"""
    propdoc(x)

Returns documentation for property `x`.
"""
propdoc(x::Function) = propdoc(property(x))
propdoc(::P) where {P<:Property} = propdoc(P)

_extract_doc(x::Markdown.MD) = _extract_doc(x.content)
_extract_doc(x::AbstractArray) = isempty(x) ? "" : _extract_doc(first(x))
_extract_doc(x::Markdown.Paragraph) = _extract_doc(x.content)
_extract_doc(x::String) = x

function propdoc(::T) where {T}
    pnames = _property_fields(T)
    return NamedTuple{pnames}(([propdoc(T, p) for p in pnames]...,))
end

"""
    prop2field(x, p) -> Symbol

Given the `x` and property `p` returns the symbol corresponding to the field
where the property is stored in `x`. If no corresponding symbol is found then
`nothing` is returned.
"""
@inline prop2field(::T, p::P) where {T,P} = prop2field(T, property(P))
prop2field(::T, ::Type{P}) where {T,P} = prop2field(T, P)
prop2field(::Type{T}, ::P) where {T,P} = prop2field(T, P)
prop2field(::Type{T}, ::Type{P}) where {T,P} = prop2field(C, property(P))
prop2field(::Type{T}, ::Type{P}) where {T,P<:Property} = nothing

"""
    sym2prop(x, sym) -> Property

Given the `x` and symbol `sym` returns the corresponding property. If no
corresponding property is found then `NoProperty` is returned.
"""
sym2prop(::T, s::Symbol) where {T} = sym2prop(T, s)

"""
Indicates the absence of a property.
"""
@defprop NotProperty{:not_property}=NotProperty

