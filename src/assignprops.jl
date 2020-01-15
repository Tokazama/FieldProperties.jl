"""
    assigned_properties(x) -> Tuple{Vararg{Symbol}}

Returns the fields labeled as with any property except `NestedProperty` using
`@assignprops`. 
"""
assigned_properties(::T) where {T} = assigned_properties(T)
assigned_properties(::Type{T}) where {T} = ()

function _propertynames(x)
    Base.@_inline_meta
    if has_nested_properties(x)
        if has_dictextension(x)
            return (assigned_properties(x)..., [_propertynames(getfield(x, f)) for f in nested_fields(x)]...,
                    keys(dictextension(x))...)
        else
            return (assigned_properties(x)..., [_propertynames(getfield(x, f)) for f in nested_fields(x)]...)
        end
    else
        if has_dictextension(x)
            return (assigned_properties(x)..., keys(dictextension(x))...)
        else
            return assigned_properties(x)
        end
    end
end

add_prop2field!(blk, pname, fname) = chain_ifelse!(blk, Expr(:call, :(===), pname, :p), fname)
add_sym2prop!(blk, pname, prop) = chain_ifelse!(blk, Expr(:call, :(===), :s, pname), prop)
function chain_ifelse!(blk::Expr, condition::Expr, trueout)
    if blk.head === :if
        if isempty(blk.args)
            push!(blk.args, condition)
            push!(blk.args, trueout)
        elseif length(blk.args) == 2
            push!(blk.args, Expr(:elseif, condition, trueout))
        else
            add_prop2field!(blk.args[end], condition, )
        end
    elseif blk.head === :elseif
        if blk.args[end] isa Expr
            add_prop2field!(blk.args[end], condition, trueout)
        else
            push!(blk.args, Expr(:elseif, condition, trueout))
        end
    end
end

function final_out!(blk, r)
    if blk.head === :if
        if length(blk.args) == 3
            final_out!(blk.args[end], r)
        else
            push!(blk.args, r)
        end
    elseif blk.head === :elseif
        if length(blk.args) == 3
            final_out!(blk.args[end], r)
        else
            push!(blk.args, r)
        end
    end
end


function parse_field_assignment(x::Expr)
    if x.head == :call
        if x.args[1] == :(=>)
            return x.args[1], x.args[2], x.args[3]
        else
            # TODO potential hook
        end
    else
        # TODO potential hook
    end
end

to_field_name(lhs::QuoteNode) = lhs
to_field_name(lhs::Symbol) = QuoteNode(lhs)

to_property_name(rhs::Symbol) = Expr(:call, :(MetadataUtils.propname), rhs)
# where :(Property(OptionalProperties))
to_property_name(rhs::Expr) = to_property_name(rhs.args[1])


to_property(rhs::Symbol) = rhs
function to_property(rhs::Expr)
    if rhs.head == :call  # assume the property is the function doing the calling
        return to_property(rhs.args[1])
    else
        # TODO potential hook
    end
end

function parse_assignment(x::Expr)
    if x.head === :call
        return x.args[1], x.args[2], x.args[3]
    end
end

function _assignprops(expr, fields...)
    blk = Expr(:block)
    nf = Expr(:tuple)
    pf = Expr(:tuple)
    T = esc(expr)

    if length(fields) === 0
        blk_sym2prop = Expr(:return, esc(MetadataUtils.NotProperty))
        blk_prop2field = Expr(:return, esc(:nothing))
    else
        blk_sym2prop = Expr(:if)
        blk_prop2field = Expr(:if)
        for field_i in fields
            btwn, lhs, rhs = parse_assignment(field_i)
            fname = to_field_name(lhs)
            prop = to_property(rhs)
            pname = to_property_name(rhs)

            if is_nested_property_expr(prop)
                has_nested_fields_bool = true
                push!(nf.args, fname)
            elseif is_dictextension_expr(rhs)
                push!(blk.args, Expr(:(=), :(MetadataUtils.dictextension_field(::Type{<:$T})), fname))
                push!(blk.args, :(MetadataUtils.dictextension(x::$T) = getfield(x, $fname)))
                if has_optional_properties_expr(rhs)
                    push!(blk.args,
                          Expr(:(=),
                               :(MetadataUtils.optional_properties(::Type{<:$T})),
                                 get_optional_properties_expr(rhs)))
                end
            else
                push!(pf.args, Expr(:call, esc(:(MetadataUtils.propname)), prop))
                add_sym2prop!(blk_sym2prop, pname, prop)
                add_prop2field!(blk_prop2field, prop, fname)
            end
        end
        if isempty(blk_sym2prop.args)
            blk_sym2prop = Expr(:return, esc(MetadataUtils.NotProperty))
            blk_prop2field = Expr(:return, esc(:nothing))
        end
        final_out!(blk_sym2prop, Expr(:return, esc(MetadataUtils.NotProperty)))
        final_out!(blk_prop2field, Expr(:return, esc(:nothing)))
    end

    push!(blk.args, :(MetadataUtils.assigned_properties(::Type{<:$T}) = $pf))
    push!(blk.args, :(MetadataUtils.prop2field(::Type{<:$T}, p::MetadataUtils.Property) = $blk_prop2field))
    push!(blk.args, :(MetadataUtils.sym2prop(::Type{<:$T}, s::Symbol) = $blk_sym2prop))
    push!(blk.args, :(MetadataUtils.nested_fields(::Type{<:$T}) = $nf))
    push!(blk.args, :(Base.getproperty(x::$T, s::Symbol) = MetadataUtils._getproperty(x, MetadataUtils.sym2prop($T, s), s)))
    push!(blk.args, :(Base.setproperty!(x::$T, s::Symbol, val) = MetadataUtils._setproperty!(x, MetadataUtils.sym2prop($T, s), s, val)))
    push!(blk.args, :(Base.propertynames(x::$T) = MetadataUtils._propertynames(x)))

    return blk
end

"""
    @assignprops

```jldoctest
julia> @defprop Property1{:prop1}

julia> struct MyStruct1
           field1
       end

julia> @assignprops(MyStruct1, :field1 => Property1)

julia> m = MyStruct1(2)

julia> propertynames(m) == (:prop1,)
true
```
"""
macro assignprops(ex, kwdefs...)
    _assignprops(ex, kwdefs...)
end
