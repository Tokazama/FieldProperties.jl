"""
    propdefault(p[, c])

Returns the default value for property `p` given the optinal context `c`.
"""
propdefault(p::AbstractProperty) = propdefault(p, not_property)
propdefault(::Type{P}) where {P<:AbstractProperty} = propdefault(P, not_property)
propdefault(p::AbstractProperty, context) = propdefault(typeof(p), context)
propdefault(::Type{<:AbstractProperty}, context) = not_property

