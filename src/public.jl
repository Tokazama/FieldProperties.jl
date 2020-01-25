
"Marks a field as publicly available through `getproperty` and possibley `setproperty!`."
struct PublicProperty <: AbstractProperty{:public,nothing} end
const public = PublicProperty()


"""
    public_fields(x) -> Tuple{Vararg{Symbol}}

Returns the fields labeled as with any property except `NestedProperty` using
`@assignprops`. 
"""
public_fields(::T) where {T} = public_fields(T)
public_fields(::Type{T}) where {T} = fieldnames(T)

is_public(x::Symbol) = x === :public

"""
    has_public_fields(x) -> Bool

Returns `true` if `x` has public fields. See [`public_fields`](@ref).
"""
@inline has_public_fields(x) = _has_public_fields(public_fields(x))
_has_public_fields(::Tuple{}) = false
_has_public_fields(::Tuple{Vararg{Any}}) = true

function get_public_property(x, s::Symbol)
    if has_public_fields(x)
        for f in public_fields(x)
            _iseq(f, s) && return not_property, getfield(x, f)
        end
    end
    return not_property, not_property
end

function set_public_property!(x, s::Symbol, val)
    if has_public_fields(x)
        for f in public_fields(x)
            if _iseq(f, s)
                setfield!(x, f, val)
                return true
            end
        end
    end
    return false
end

