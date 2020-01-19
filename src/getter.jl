#=
1. `x` has field directly mapping to property `p` but `s` is the interface to reach
    the property (e.g., `x.s`), so we go from propety to exact field (ie prop2field(x, p)).
2. `x.s` couldn't find the property so it is one of:
    - In a nested property
    - Unassigned and in the dictextension
    - Optionally assigned and IS in the dictextension
    - Optionally assigned and NOT in the dictextension
    - Not available anywhere
3. `p(x)` couldn't map property to symbol
=#

#=
Return type of getter is a property flagging the formal property associated with the call and
the value assigned value to that property. Possible outcomes of getter are:

* flag::NotProperty,      val::NotProperty - couldn't associate property or value with call to x                       -> throw error
* flag::NotProperty,      val::Any         - couldn't associated property with call to x but found it in dictextension -> No type inference enforced
* flag::AbstractProperty, val::Any         - found property associated with call to x and an assigned value            -> Attempt to enforce type of val using flag
* flag::AbstractProperty, val::NotProperty - found property associated with call to x but val wasn't assigned          -> look for default value using flag, if there isn't one throw error
=#

@inline getter(x, p::AbstractProperty) = getter(x, p, prop2field(x, p))
@inline getter(x, s::Symbol) = getter(x, sym2prop(x, s), s)
getter(x, p::AbstractProperty, s::Symbol) = (p, getfield(x, prop2field(x, p)))   # 1
function getter(x, p::NotProperty, s::Symbol)                                    # 2
    Base.@_inline_meta
    if has_nested_properties(x)
        for f in nested_fields(x)
            out = getter(getfield(x, f), s)
            first(out) !== not_property && return out
        end
    elseif has_dictextension(x)
        if has_optional_properties(x)
            for op in optional_properties(x)
                propname(op) === s && return op, get(dictextension(x), s, not_property)
            end
        end
        return not_property, get(dictextension(x), s, not_property)
    else
        return not_property, not_property
    end
end
function getter(x, p::AbstractProperty, s::Nothing)                              # 3
    Base.@_inline_meta
    if has_nested_properties(x)
        for f in nested_fields(x)
            out = getter(getfield(x, f), p)
            first(out) !== not_property && return out
        end
    elseif has_dictextension(x)
        return p, get(dictextension(x), propname(p), not_property)
    else
        return p, not_property
    end
end

##
(p::AbstractProperty{name,Getter})(x) where {name} = _getproperty(x, p)

_getproperty(x::T, s::Symbol) where {T} = _getproperty(x, sym2prop(T, s), s)
_getproperty(x::T, p::AbstractProperty) where {T} = _getproperty(x, p, prop2field(T, p))
function _getproperty(x, p, s)  where {T}
    flag, val = getter(x, p, s)
    return __getproperty(flag, val, x, s)
end

# property was found and has formal assigned property (ie flag)
__getproperty(flag::AbstractProperty, val, x, s) = propconvert(flag, s, val, x)::proptype(flag, x)
# was able to to find a property assignment, but not an assigned value (optional)
function __getproperty(flag::AbstractProperty, ::NotProperty, x, s)
    val = propdefault(flag, x)
    return val === not_property ? throw_property_error(x, s) : propconvert(flag, s, val, x)::proptype(flag, x)
end
# property wasn't found at any level
__getproperty(::NotProperty, ::NotProperty, x, s) = throw_property_error(x, s)
# can't infer type because property isn't nested, assigned, or optional
__getproperty(::NotProperty, val, x, s) = val

throw_property_error(x, s) = error("type $(typeof(x).name) does not have property $s")
