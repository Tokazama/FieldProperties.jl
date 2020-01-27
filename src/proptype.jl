"""
    proptype(p[, context]) -> Type

Return the appropriate type for property `p` given `context`. This method allows
unique type restrictions given different types for `context`.
"""
proptype(p::AbstractProperty) = proptype(typeof(p))
proptype(::Type{P}) where {P<:AbstractProperty} = proptype(P, not_property)
proptype(p::AbstractProperty, context) = proptype(typeof(p), context)
proptype(::Type{<:AbstractProperty}, context) = Any

