(p::AbstractProperty{name,Getter})(x) where {name} = _getproperty(x, p)

# Only ensure type stability when going through _getproperty/_setproperty!
function _getproperty(x::T, s::Symbol) where {T}
    Base.@_inline_meta
    return _getproperty(x, sym2prop(T, s), s)
end
function _getproperty(x::T, p::AbstractProperty) where {T}
    Base.@_inline_meta
    return _getproperty(x, p, prop2field(T, p))
end

function _getproperty(x, p, s)  where {T}
    Base.@_inline_meta
    return __getproperty(x, p, s, getter(x, p, s))
end

# this level checks for optional properties
function __getproperty(x, p::NotProperty, s, v)
    for op in optional_properties(x)
        propname(op) === s && return __getproperty(x, op, s, v)
    end
    return ___getproperty(x, p, s, v)
end
__getproperty(x, p, s, v) = ___getproperty(x, p, s, v)

# this next level checks for property defaults
___getproperty(x, p, s, v::NotProperty) = prop_or_error(x, p, s, propdefault(p, x))
___getproperty(x, p, s, v) = propconvert(p, s, v, x)

function prop_or_error(x, p, s, ::NotProperty)
    error("type $(typeof(x).name) does not have property $s")
end
prop_or_error(x, p, s, v) = propconvert(p, s, v, x)

@inline getter(x, p::AbstractProperty) = getter(x, p, prop2field(x, p))
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
getter(x, p::AbstractProperty, s::Symbol) = getfield(x, prop2field(x, p))   # 1
function getter(x, p::NotProperty, s::Symbol)                   # 2
    Base.@_inline_meta
    if has_nested_properties(x)
        for f in _nested_fields(x)
            out = getter(getfield(x, f), s)
            out !== not_property && return out
        end
    elseif has_dictextension(x)
        out = get(dictextension(x), s, not_property)
    else
        out = not_property
    end
    return out
end
function getter(x, p::AbstractProperty, s::Nothing)                         # 3
    Base.@_inline_meta
    if has_nested_properties(x)
        for f in _nested_fields(x)
            out = getter(getfield(x, f), p)
            out !== not_property && return out
        end
    elseif has_dictextension(x)
        return get(dictextension(x), propname(p), not_property)
    else
        return not_property
    end
end
