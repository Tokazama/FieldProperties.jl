"""
Indicator for a field containing properties nested within a structure.
"""
struct NestedProperty <: AbstractProperty{:nested,nothing} end
const nested = NestedProperty()

"""
    nested_fields(x) -> Tuple{Vararg{Symbol}}

Returns the fields labeled as `NestedProperty` using `@assignprops`
"""
nested_fields(::T) where {T} = nested_fields(T)
nested_fields(::Type{T}) where {T} = ()

"""
    has_nested_fields(::T) -> Bool

Returns `true` if `T` has fields that contain nested properties.
"""
@inline has_nested_fields(x) = _has_nested_fields(nested_fields(x))
_has_nested_fields(::Tuple{}) = false
_has_nested_fields(::Tuple{Vararg{Symbol}}) = true

is_nested(x::Symbol) = (x === :NestedProperty) | (x === :nested)
is_nested(x::Expr) = is_nested(x.args[1])

function get_nested_property(x, p, s)
    if has_nested_fields(x)
        for f in nested_fields(x)
            flag, val = getter(getfield(x, f), p, s)
            !is_not_property(val) && return flag, val
        end
    end
    return not_property, not_property
end

function set_nested_property!(x, p, s, val)
    out = false
    if has_nested_fields(x)
        for f in nested_fields(x)
            out = setter!(getfield(x, f), p, s, val)
            out && break
        end
    end
    return out
end
