(p::AbstractProperty{name,setproperty!})(x, val) where {name} = _setproperty!(x, p, val)

_setproperty!(x, s::Symbol, val) = _setproperty!(x, sym2prop(x, s), s, val)
_setproperty!(x, p::AbstractProperty, val) = _setproperty!(x, p, prop2field(x, p), val)
_setproperty!(x, p, s, val) = (setter!(x, p, s, propconvert(p, s, val, x)); x)

@inline setter!(x, p::AbstractProperty, val, toplevel::Bool) = setter!(x, p, prop2field(x, p), val, toplevel)
@inline setter!(x, s::Symbol, val, toplevel::Bool) = setter!(x, sym2prop(x, s), s, val, toplevel)

# need to run sym2prop one more time in case property is mapped to field with
# different name
function setter!(x, p::AbstractProperty, s::Symbol, val)
    setfield!(x, prop2field(x, p), val)
    return true
end
function setter!(x, p::NotProperty, s::Symbol, val)
    Base.@_inline_meta
    out = set_public_property!(x, s, val)
    if !out
        out = set_nested_property!(x, not_property, s, val)
    end
    if !out
        out = set_dictextension_property!(x, s, val)
    end
    return out
end
function setter!(x, p::AbstractProperty, ::Nothing, val)
    Base.@_inline_meta
    out = get_nested_property(x, p, nothing)
    if !out
        out = set_dictextension_property!(x, p, val)
    end
    return out
end




