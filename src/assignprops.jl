#=
    _property_fields(T) -> Tuple{Vararg{Symbol}}

Returns the fields labeled as with any property except `NestedProperty` using
`@assignprops`. 
=#
_property_fields(::T) where {T} = _property_fields(T)
_property_fields(::Type{T}) where {T} = ()

function _propertynames(x)
    Base.@_inline_meta
    if has_nested_properties(x)
        return (_property_fields(x)...,
                [_property_fields(getfield(x, f)) for f in _nested_fields(x)]...)
    else
        return _property_fields(x)
    end
end
function _propertynames(x::AbstractDict{Symbol})
    Base.@_inline_meta
    if has_nested_properties(x)
        return (_property_fields(x)...,
                [_property_fields(getfield(x, f)) for f in _nested_fields(x)]...,
                keys(x)...)
    else
        return (_property_fields(x)..., keys(x)...)
    end
end
_is_nested_properties(x::Symbol) = x === :NestedProperty

if_exact_eq(x, y, trueout, falseout) = Expr(:if, Expr(:call, :(===), x, y), Expr(:return, trueout), falseout)

function _assignprops(ex, kwdefs...)
    blk_sym2prop = Expr(:return, esc(FieldProperties.NotProperty))
    blk_prop2sym = Expr(:return, :nothing)
    s = esc(:s)
    val = esc(:val)
    T = esc(ex)
    p = esc(:p)
    x = esc(:x)
    nested_fields = Expr(:tuple)
    property_fields = Expr(:tuple)
    for kwdefs_i in kwdefs
        field_sym = kwdefs_i.args[2]
        if field_sym isa Symbol
            field_sym = QuoteNode(field_sym)
        elseif !isa(field_sym, QuoteNode)
            error("assigned field $field_sym must be a Symbol.")
        end

        if _is_nested_properties(kwdefs_i.args[3])
            push!(nested_fields.args, field_sym)
        else
            field_prop = kwdefs_i.args[3]
            if field_prop isa Symbol  # is QuoteNode
                field_prop = esc(field_prop)
            else
                error("")
            end
            push!(property_fields.args, :(FieldProperties.propname($field_prop)))
            blk_sym2prop = if_exact_eq(s, :(FieldProperties.propname($field_prop)), field_prop, blk_sym2prop)
            blk_prop2sym = if_exact_eq(p, field_prop, field_sym, blk_prop2sym)
        end
    end
    return quote
        #FieldProperties.prop2sym(::Type{<:$T}, $p::FieldProperties.Property) = $blk_prop2sym
        FieldProperties.prop2sym(::Type{<:$T}, $p::P) where {P<:FieldProperties.Property} = $blk_prop2sym

        FieldProperties.sym2prop(::Type{<:$T}, $s::Symbol) = $blk_sym2prop

        FieldProperties._nested_fields(::Type{<:$T}) = $nested_fields

        FieldProperties._property_fields(::Type{<:$T}) = $property_fields

        Base.getproperty($x::$T, $s::Symbol) = FieldProperties._getproperty($x, $s)

        Base.setproperty!($x::$T, $s::Symbol, $val) = FieldProperties._setproperty!($x, $s, $val)

        Base.propertynames($x::$T) = FieldProperties._propertynames(x)
    end
end


"""
    @assignprops

## Searching For Properties in Structures

The `@assignprops` macro alters behavior by:

1. Only considering fields specifically assigned by the `@assignprops` macro as properties
2. Permits arbitrarily nested properties by recursively searching through fields marked as `NestedProperty`
3. If the structure is a dictionary with symbol keys then all key-values are considered properties. This permits nested proeprties to serve as reservoir of an arbitrary number of proeprties.

```jldoctest propexamples
julia> using BenchmarkTools

julia> struct MyStruct1
           field1
       end

julia> @assignprops(MyStruct1, :field1 => Property1)

julia> m = MyStruct1(2)

julia> propertynames(m) == (:prop1,)
true

```

struct MyStruct1
    field1
end

@assignprops(MyStruct1, :field1 => Property1)
"""
macro assignprops(ex, kwdefs...)
    _assignprops(ex, kwdefs...)
end
