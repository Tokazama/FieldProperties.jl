
"""
Dictionary that flexibly extends capacity to store properties.
"""
@defprop DictExtension{:dictextension}

"""
    has_dictextension(::T) -> Bool

Returns `true` if `T` has fields that containing extensible dictionary of properties.
"""
has_dictextension(::T) where {T} = has_dictextension(T)
has_dictextension(::Type{T}) where {T} = false

"""
    optional_properties(x) -> Tuple

Returns tuple of optionally defined properties for `x`.
"""
optional_properties(::T) where {T} = optional_properties(T)
optional_properties(::Type{T}) where {T} = ()

"""
    has_public_fields(x) -> Bool

Returns `true` if `x` has optional properties. See [`optional_properties`](@ref).
"""
@inline has_optional_properties(x) = _has_optional_properties(optional_properties(x))
_has_optional_properties(::Tuple{}) = false
_has_optional_properties(::Tuple{Vararg{Any}}) = true

function get_dictextension_property(x, p)
    if has_dictextension(x)
        if has_optional_properties(x)
            for p_i in optional_properties(x)
                if _iseq(p_i, p)
                    return p_i, get(dictextension(x), _propname(p), not_property)
                end
            end
        else
            return not_property, get(dictextension(x), _propname(p), not_property)
        end
    else
        return not_property, not_property
    end
end

# optional properties doesn't matter at this point because proper type should
# be enforced early in call (in the `_setproperty!` methods)
function set_dictextension_property!(x, p, val)
    if has_dictextension(x)
        setindex!(dictextension(x), val, _propname(p))
        return true
    else
        return false
    end
end

#=
Parsing expression
:(field => dictproprty)
or
:(field => dictproprty(Prop1, Prop2))
=#


is_dictextension(x::Symbol) = (x === :DictExtension) | (x === :dictextension)
is_dictextension(x::AbstractArray) = is_dictextension(x[1])
function is_dictextension(x::Expr)
    if x.head == :call
        if x.args[1] == :(=>)
            return is_dictextension(x.args[3])
        elseif x.args[1] isa Symbol # may be function call e.g, fxn(y) where x.args[1] would equal fxn
            return is_dictextension(x.args[1])
        end
    end
end

has_optional_properties_expr(x::Symbol) = false
function has_optional_properties_expr(x::Expr)
    if x.head == :call
        if x.args[1] == :(=>)
            return has_optional_properties_expr(x.args[3])
        elseif is_dictextension(x.args[1])
            return true
        end
    end
end

