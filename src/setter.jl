_setproperty!(x, s::Symbol, val) = _setproperty!(x, sym2prop(x, s), s, val)
_setproperty!(x, p::Property, val) = _setproperty!(x, p, prop2field(x, p), val)
function _setproperty!(x, p, s, val)
    setter!(x, p, s, propconvert(x, p, val), true)
    return x
end

#=
    setter!(x, p::Property, s::Symbol, val)
    setter!(x, s::Symbol, val)
    setter!(x, p::Property, val)

* toplevel::Bool: if `false` means that current structure has been recursed into and is
  a nested property field. This prevents from setting proprties in `dictproperties` on anything
  but the top level. If a nested structure has dictproperties it can be set by using x.nested.somevalue_into_dictproperties
=#
@inline setter!(x, p::Property, val, toplevel::Bool) = setter!(x, p, prop2field(x, p), val, toplevel)
@inline setter!(x, s::Symbol, val, toplevel::Bool) = setter!(x, sym2prop(x, s), s, val, toplevel)

# need to run sym2prop one more time in case property is mapped to field with different name
setter!(x, p::Property, s::Symbol, val, toplevel::Bool) = setfield!(x, prop2field(x, p), val)
function setter!(x, p::NotPropertyType, s::Symbol, val, toplevel::Bool)
    Base.@_inline_meta
    if has_nested_properties(x)
        for f in _nested_fields(x)
            out = setter!(getfield(x, f), s, val, false)
            out && break
        end
    elseif toplevel & has_dictextension(x)
        setindex!(dictextension(x), val, s)
        out = true
    else
        out = false
    end
    return out
end
function setter!(x, p::Property, s::Nothing, val, toplevel::Bool)
    Base.@_inline_meta
    if has_nested_properties(x)
        for f in _nested_fields(x)
            out = setter!(getfield(x, f), p, val, false)
            out && break
        end
    elseif has_dictextension(x)
        setindex!(dictextension(x), val, propname(p))
        out = true
    else
        out = false
    end
    return out
end
