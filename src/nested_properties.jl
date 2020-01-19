"""
Indicator for a field containing properties nested within a structure.
"""
@defprop NestedProperty{:nested_property}

"""
    has_nested_properties(::T) -> Bool

Returns `true` if `T` has fields that contain nested properties.
"""
@inline has_nested_properties(::T) where {T} = has_nested_properties(T)
@inline has_nested_properties(::Type{T}) where {T} = _has_nested_properties(nested_fields(T))
_has_nested_properties(::Tuple{}) = false
_has_nested_properties(::Tuple{Vararg{Symbol}}) = true

"""
    nested_fields(x) -> Tuple{Vararg{Symbol}}

Returns the fields labeled as `NestedProperty` using `@assignprops`
"""
nested_fields(::T) where {T} = nested_fields(T)
nested_fields(::Type{T}) where {T} = ()

## macro utils
is_nested_property_expr(x::Symbol) = (x === :NestedProperty) | (x === :nested_property)

def_nested_fields_expr(T) = Expr(:(=), :(FieldProperties.nested_fields(::$T)), Expr(:tuple))

