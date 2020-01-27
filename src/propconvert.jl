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

