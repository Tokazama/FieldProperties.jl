# Only ensure type stability when going through _getproperty/_setproperty!
function _getproperty(x::T, s::Symbol) where {T}
    Base.@_inline_meta
    return _getproperty(x, sym2prop(T, s), s)
end
function _getproperty(x::T, p::Property) where {T}
    Base.@_inline_meta
    return _getproperty(x, p, prop2field(T, p))
end

function _getproperty(x, p, s)  where {T}
    Base.@_inline_meta
    return __getproperty(x, p, s, getter(x, p, s))
end

# this level checks for optional properties
function __getproperty(x, p::NotPropertyType, s, v)
    for op in optional_properties(x)
        propname(op) === s && return __getproperty(x, op, s, v)
    end
    return ___getproperty(x, p, s, v)
end
__getproperty(x, p, s, v) = ___getproperty(x, p, s, v)

# this next level checks for property defaults
___getproperty(x, p, s, v::NotPropertyType) = prop_or_error(x, p, s, propdefault(p, x))
___getproperty(x, p, s, v) = propconvert(p, s, v, x)

function prop_or_error(x, p, s, ::NotPropertyType)
    error("type $(typeof(x).name) does not have property $s")
end
prop_or_error(x, p, s, v) = propconvert(p, s, v, x)

@inline getter(x, p::Property) = getter(x, p, prop2field(x, p))
@inline getter(x, s::Symbol) = getter(x, sym2prop(x, s), s)

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
getter(x, p::Property, s::Symbol) = getfield(x, prop2field(x, p))   # 1
function getter(x, p::NotPropertyType, s::Symbol)                   # 2
    Base.@_inline_meta
    if has_nested_properties(x)
        for f in _nested_fields(x)
            out = getter(getfield(x, f), s)
            out !== NotProperty && return out
        end
    elseif has_dictextension(x)
        out = get(dictextension(x), s, NotProperty)
    else
        out = NotProperty
    end
    return out
end
function getter(x, p::Property, s::Nothing)                         # 3
    Base.@_inline_meta
    if has_nested_properties(x)
        for f in _nested_fields(x)
            out = getter(getfield(x, f), p)
            out !== NotProperty && return out
        end
    elseif has_dictextension(x)
        return get(dictextension(x), propname(p), NotProperty)
    else
        return NotProperty
    end
end
