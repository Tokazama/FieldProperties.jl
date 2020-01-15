# Only ensure type stability when going through _getproperty/_setproperty!
function _getproperty(x::T, s::Symbol) where {T}
    Base.@_inline_meta
    return _getproperty(x, sym2prop(T, s), s)
end
function _getproperty(x::T, p::Property) where {T}
    Base.@_inline_meta
    return _getproperty(x, p, prop2sym(T, p))
end

function _getproperty(x, p, s)  where {T} 
    Base.@_inline_meta
    return __getproperty(x, p, s, getter(x, p, s))
end

# last level of indirection checks if there are any defaults
__getproperty(x, p, s, v::NotPropertyType) = ___getproperty(x, p, s, propdefault(p, x))
__getproperty(x, p, s, v) = propconvert(p, s, v, x)
function ___getproperty(x, p, s, v::NotPropertyType)
    error("type $(typeof(x).name) does not have property $s")
end
___getproperty(x, p, s, v) = propconvert(p, s, v, x)

"""
    getter(x, p)
"""
@inline getter(x, p::Property) = getter(x, p, prop2sym(x, p))
@inline getter(x, s::Symbol) = getter(x, sym2prop(x, s), s)

# need to run sym2prop one more time in case property is mapped to field with different name
getter(x, p::Property, s::Symbol) = getfield(x, prop2sym(x, p))
function getter(x, p::Property{:not_property}, s::Symbol)
    Base.@_inline_meta
    if has_nested_properties(x)
        for f in _nested_fields(x)
            out = getter(getfield(x, f), s)
            out !== NotProperty && return out
        end
    elseif has_dictproperty(x)
        out = get(getfield(x, prop2sym(x, DictProperty)), s, NotProperty)
    else
        out = NotProperty
    end
    return out
end
function getter(x, p::Property, s::Nothing)
    Base.@_inline_meta
    if has_nested_properties(x)
        for f in _nested_fields(x)
            out = getter(getfield(x, f), p)
            out !== NotProperty && return out
        end
    elseif has_dictproperty(x)
        return get(getfield(x, prop2sym(x, DictProperty)), propname(p), NotProperty)
    else
        return NotProperty
    end
end
