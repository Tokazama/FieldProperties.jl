"""
Dictionary that flexibly extends capacity to store properties.
"""
@defprop DictExtension{:dictextension}::AbstractDict{Symbol}


dictextension_field(::T) where {T} = dictextension_field(T)
dictextension_field(::Type{T}) where {T} = NotProperty

"""
    has_dictextension(::T) -> Bool

Returns `true` if `T` has fields that containing extensible dictionary of properties.
"""
@inline has_dictextension(::T) where {T} = has_dictextension(T)
@inline has_dictextension(::Type{T}) where {T} = _has_dictextension(dictextension_field(T))
_has_dictextension(::NotPropertyType) = false
_has_dictextension(::Symbol) = true

"""
    optional_properties(x) -> Tuple

Returns tuple of optionally defined properties for `x`.
"""
optional_properties(::T) where {T} = optional_properties(T)
optional_properties(::Type{T}) where {T} = ()

@inline has_optional_properties(::T) where {T} = has_optional_properties(T)
@inline has_optional_properties(::Type{T}) where {T} = _has_optional_properties(optional_properties(T))
_has_optional_properties(::Tuple{}) = false
_has_optional_properties(::Tuple{Vararg{Any}}) = true

#=
Parsing expression
:(field => dictproprty)
or
:(field => dictproprty(Prop1, Prop2))
=#

is_dictextension_expr(x::Symbol) = (x === :DictExtension) | (x === :dictextension)
is_dictextension_expr(x::AbstractArray) = is_dictextension_expr(x[1])
function is_dictextension_expr(x::Expr)
    if x.head == :call
        if x.args[1] == :(=>)
            return is_dictextension_expr(x.args[3])
        elseif x.args[1] isa Symbol # may be function call e.g, fxn(y) where x.args[1] would equal fxn
            return is_dictextension_expr(x.args[1])
        end
    end
end

has_optional_properties_expr(x::Symbol) = false
function has_optional_properties_expr(x::Expr)
    if x.head == :call
        if x.args[1] == :(=>)
            return has_optional_properties_expr(x.args[3])
        elseif is_dictextension_expr(x.args[1])
            return true
        end
    end
end

function get_optional_properties_expr(x::Expr)
    if x.head == :call
        if x.args[1] == :(=>)
            return get_optional_properties_expr(x.args[3])
        elseif is_dictextension_expr(x.args[1])
            return get_optional_properties_expr(x.args)
            #return length(x.args) > 1 ? Expr(:tuple, x.args[2:end]...) : Expr(:tuple)
        end
    end
end
function get_optional_properties_expr(x::AbstractArray)
    return length(x) > 1 ? Expr(:tuple, esc.(x[2:end])...) : Expr(:tuple)
end

