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
        if has_dictproperty(x)
            return (_property_fields(x)...,
                    [_propertynames(getfield(x, f)) for f in _nested_fields(x)]...,
                    keys(getfield(x, prop2sym(x, DictProperty)))...)
        else
            return (_property_fields(x)..., [_propertynames(getfield(x, f)) for f in _nested_fields(x)]...)
        end
    else
        if has_dictproperty(x)
            return (_property_fields(x)..., keys(getfield(x, prop2sym(x, DictProperty)))...)
        else
            return _property_fields(x)
        end
    end
end
_is_nested_properties(x::Symbol) = x === :NestedProperty
_is_dictproperty(x::Symbol) = (x === :DictProperty) | (x === :dictproperty)


function if_exact_eq(x, y, trueout, falseout)
    return Expr(:if, Expr(:call, :(===), x, y), Expr(:return, trueout), falseout)
end


function _add_elseif!(expr::Expr, x, y, trueout)
    if expr.head === :if
        if isempty(expr.args)
            push!(expr.args, Expr(:call, :(===), x, y), trueout)
        elseif length(expr.args) == 2
            push!(expr.args, Expr(:elseif, Expr(:call, :(===), x, y), trueout))
        else
            _add_elseif!(expr.args[end], Expr(:call, :(===), x, y), trueout)
        end
    elseif expr.head === :elseif
        if expr.args[end] isa Expr
            _add_elseif!(expr.args[end], Expr(:call, :(===), x, y), trueout)
        else
            push!(expr.args, Expr(:elseif, Expr(:call, :(===), x, y), trueout))
        end
    end
end

function _final_else_return!(expr, r)
    if expr.head === :if
        if length(expr.args) == 3
            _final_else_return!(expr.args[end], r)
        else
            push!(expr.args, r)
        end
    elseif expr.head === :elseif
        if length(expr.args) == 3
            _final_else_return!(expr.args[end], r)
        else
            push!(expr.args, r)
        end
    end
end

function _assignprops(ex, kwdefs...)
    s = esc(:s)
    val = esc(:val)
    T = esc(ex)
    p = esc(:p)
    x = esc(:x)
    S = esc(:Symbol)
    TYPE = esc(Type)
    pname = esc(Expr(:., :MetadataUtils, QuoteNode(:propname)))
    nested_fields = Expr(:tuple)
    property_fields = Expr(:tuple)
    _defiend_dictproperty = false
    if length(kwdefs) === 0
        blk_sym2prop = Expr(:return, esc(MetadataUtils.NotProperty))
        blk_prop2sym = Expr(:return, esc(:nothing))
    else
        blk_sym2prop = Expr(:if)
        blk_prop2sym = Expr(:if)
        for kwdefs_i in kwdefs
            field_sym = kwdefs_i.args[2]
            if field_sym isa Symbol
                field_sym = QuoteNode(field_sym)
            elseif !isa(field_sym, QuoteNode)
                error("assigned field $field_sym must be a Symbol.")
            end

            if _is_nested_properties(kwdefs_i.args[3])
                push!(nested_fields.args, field_sym)
            elseif _is_dictproperty(kwdefs_i.args[3])
                field_prop = kwdefs_i.args[3]
                if field_prop isa Symbol  # is QuoteNode
                    field_prop = esc(field_prop)
                else
                    error("")
                end
                _defiend_dictproperty = true
                _add_elseif!(blk_sym2prop, s, :($pname($field_prop)), Expr(:return, field_prop))
                _add_elseif!(blk_prop2sym, p, field_prop, Expr(:return, field_sym))
            else
                field_prop = kwdefs_i.args[3]
                if field_prop isa Symbol  # is QuoteNode
                    field_prop = esc(field_prop)
                else
                    error("")
                end
                push!(property_fields.args, :($pname($field_prop)))
                _add_elseif!(blk_sym2prop, s, :($pname($field_prop)), Expr(:return, field_prop))
                _add_elseif!(blk_prop2sym, p, field_prop, Expr(:return, field_sym))
            end
        end
        _final_else_return!(blk_sym2prop, Expr(:return, esc(MetadataUtils.NotProperty)))
        _final_else_return!(blk_prop2sym, Expr(:return, esc(:nothing)))
    end
    p2s = esc(Expr(:., :MetadataUtils, QuoteNode(:prop2sym)))
    P2S = Expr(:function, :($p2s(::$TYPE{<:$T}, $p::$(esc(MetadataUtils.Property)))), blk_prop2sym)
    s2p = esc(Expr(:., :MetadataUtils, QuoteNode(:sym2prop)))
    S2P = Expr(:function, :($s2p(::$TYPE{<:$T}, $s::$S)), blk_sym2prop)
    blk = quote
        #MetadataUtils.prop2sym(::Type{<:$T}, $p::MetadataUtils.Property) = $blk_prop2sym
        $P2S

        $S2P

        MetadataUtils._nested_fields(::$TYPE{<:$T}) = $nested_fields

        MetadataUtils._property_fields(::$TYPE{<:$T}) = $property_fields

        Base.getproperty($x::$T, $s::$S) = MetadataUtils._getproperty($x, $s2p($T, $s), $s)

        Base.setproperty!($x::$T, $s::$S, $val) = MetadataUtils._setproperty!($x, $s, $val)

        Base.propertynames($x::$T) = MetadataUtils._propertynames($x)
    end
    if _defiend_dictproperty
        push!(blk.args, :(MetadataUtils.has_dictproperty(::$TYPE{<:$T}) = true))
    end
    return blk
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
