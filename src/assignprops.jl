
function get_optional_properties_expr!(a, x::Expr)
    if iscall(x)
        if x.args[1] == :(=>)
            return get_optional_properties_expr!(a, x.args[3],)
        elseif is_dictextension(x.args[1])
            return get_optional_properties_expr!(a, x.args,)
            #return length(x.args) > 1 ? Expr(:tuple, x.args[2:end]...) : Expr(:tuple)
        end
    end
end

get_optional_properties_expr!(a, x::AbstractArray) = append!(a, esc.(x[2:end]))

function parse_assignment(x::Expr)
    if iscall(x)
        return x.args[1], x.args[2], x.args[3]
    end
end

to_field_name(lhs::QuoteNode) = lhs
to_field_name(lhs::Symbol) = QuoteNode(lhs)
function to_field_name(rhs::Expr)
    if iscall(rhs) && rhs.args[1] == :(=>)
        return to_field_name(rhs.args[2])
    end
end

_type(struct_type) = Expr(:(::), Expr(:curly, esc(:Type), Expr(:<:, struct_type)))

function chain_ifelse!(blk::Expr, condition::Expr, trueout)
    if blk.head === :if
        if isempty(blk.args)
            push!(blk.args, condition)
            push!(blk.args, trueout)
        elseif length(blk.args) == 2
            push!(blk.args, Expr(:elseif, condition, trueout))
        else
            chain_ifelse!(blk.args[end], condition, trueout)
        end
    elseif blk.head === :elseif
        if length(blk.args) == 2
            push!(blk.args, Expr(:elseif, condition, trueout))
        else
            chain_ifelse!(blk.args[end], condition, trueout)
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

to_property_name(rhs::Symbol) = callexpr(dotexpr(:FieldProperties, :propname), esc(rhs))
# where :(Property(OptionalProperties))
function to_property_name(x::Expr)
    if iscall(x) && x.args[1] == :(=>)
        return to_property_name(x.args[3])
    end
end
to_property_name(rhs::QuoteNode) = to_property_name(rhs.value)

to_property(rhs::QuoteNode) = rhs.value
to_property(rhs::Symbol) = rhs
function to_property(x::Expr)
    if iscall(x) && x.args[1] == :(=>)
        return to_property(x.args[3])
    end
end

# Changes to base functions
function def_propertynames(struct_type)
    fxnexpr(
        callexpr(dotexpr(:Base, :propertynames), var(:x, struct_type)),
        callexpr(dotexpr(:FieldProperties, :_propertynames), esc(:x))
    )
end

function def_getproperty(struct_type)
    fxnexpr(
         callexpr(dotexpr(:Base, :getproperty), var(:x, struct_type), var(:s, :Symbol)),
         callexpr(dotexpr(:FieldProperties, :_getproperty),
                  esc(:x),
                  callexpr(dotexpr(:FieldProperties, :sym2prop), esc(:x), esc(:s)), esc(:s)
         )
    )
end

function def_setproperty(struct_type)
    fxnexpr(
         callexpr(dotexpr(:Base, :setproperty!), var(:x, struct_type), var(:s, :Symbol), esc(:val)),
         callexpr(dotexpr(:FieldProperties, :_setproperty!), esc(:x),
              callexpr(dotexpr(:FieldProperties, :sym2prop), esc(:x), esc(:s)), esc(:s), esc(:val))
    )
end

# Find fields/properties
function def_sym2prop(struct_type, p, f)
    blk = Expr(:if)
    for (f_i, p_i) in zip(f,p)
        chain_ifelse!(
            blk,
            callexpr(:(===), to_property_name(p_i), esc(:s)),
            Expr(:return, esc(to_property(p_i)))
        )
    end
    final_out!(blk, Expr(:return, esc(FieldProperties.not_property)))
    fxnexpr(callexpr(dotexpr(:FieldProperties, :sym2prop), _type(struct_type), var(:s, :Symbol)), blk)
end

function def_prop2field(struct_type, p, f)
    blk = Expr(:if)

    for (f_i, p_i) in zip(f,p)
        chain_ifelse!(
            blk,
            callexpr(:(===), to_property_name(p_i), callexpr(dotexpr(:FieldProperties, :propname), esc(:p))),
            Expr(:return, f_i)
       )
    end
    final_out!(blk, Expr(:return, esc(:nothing)))
    fxnexpr(callexpr(dotexpr(:FieldProperties, :prop2field), _type(struct_type), var(:p, :AbstractProperty)), blk)
end

# Special field identifiers
function def_nested_fields(struct_type::Expr, a::Array)
    return def_nested_fields(struct_type, Expr(:tuple, a...))
end
function def_nested_fields(struct_type::Expr, f::Expr)
    return fxnexpr(callexpr(dotexpr(:FieldProperties, :nested_fields), _type(struct_type)), f)
end

function def_public_fields(struct_type::Expr, a::Array)
    return def_public_fields(struct_type, Expr(:tuple, a...))
end
function def_public_fields(struct_type::Expr, f::Expr)
    return fxnexpr(callexpr(dotexpr(:FieldProperties, :public_fields), _type(struct_type)), f)
end

function def_assigned_fields(struct_type::Expr, pn::Array)
    return def_assigned_fields(struct_type, Expr(:tuple, to_property_name.(pn)...))
end
function def_assigned_fields(struct_type::Expr, pn::Expr)
    return fxnexpr(callexpr(dotexpr(:FieldProperties, :assigned_fields), _type(struct_type)), pn)
end

function def_optional_properties(struct_type, p::Array)
    return def_optional_properties(struct_type, Expr(:tuple, p...))
end
function def_optional_properties(struct_type, p::Expr)
    return fxnexpr(callexpr(dotexpr(:FieldProperties, :optional_properties), _type(struct_type)), p)
end

function def_dictextension(struct_type, f::QuoteNode)
    fxnexpr(
        callexpr(dotexpr(:FieldProperties, :dictextension), var(:x, struct_type)),
        callexpr(esc(:getfield), esc(:x), f)
    )
end

function def_has_dictextension(struct_type)
    fxnexpr(callexpr(dotexpr(:FieldProperties, :has_dictextension), var(:x, struct_type)), Expr(:return, true))
end

function __assignprops(
    struct_type,   # type being defined
    ap,            # assigned properties
    af,            # assigned fields
    nf,            # nested fields
    op,            # optional properties
    de_field,      # dictextension field
    pf
   )
    blk = Expr(:block)

    push!(blk.args, def_propertynames(struct_type))
    push!(blk.args, def_getproperty(struct_type))
    push!(blk.args, def_setproperty(struct_type))

    if !isempty(ap)
        push!(blk.args, def_sym2prop(struct_type, ap, af))
    end

    if !isempty(af)
        push!(blk.args, def_prop2field(struct_type, ap, af))
    end

    if !isempty(ap)
        push!(blk.args, def_assigned_fields(struct_type, ap))
    end

    push!(blk.args, def_public_fields(struct_type, pf))

    if !isempty(nf)
        push!(blk.args, def_nested_fields(struct_type, nf))
    end

    if !isnothing(de_field)
        push!(blk.args, def_dictextension(struct_type, de_field))
        push!(blk.args, def_has_dictextension(struct_type))
    end

    push!(blk.args, def_optional_properties(struct_type, op))

    return blk
end

function _assignprops(ex, fields...)
    struct_type = esc(ex)
    ap = []             # assigned properties
    af = []             # assigned fields
    nf = []             # nested fields
    op = []             # optional properties
    de_field = nothing  # dictextension field
    pf = []             # public fields

    for field_i in fields
        btwn, lhs, rhs = parse_assignment(field_i)
        f = to_field_name(lhs)
        if is_nested(rhs)
            push!(nf, f)
        elseif is_dictextension(rhs)
            de_field = f
            if has_optional_properties_expr(rhs)
                get_optional_properties_expr!(op, rhs)
            end
        elseif is_public(rhs)
            push!(pf, f)
        else
            push!(af, f)
            push!(ap, rhs)
        end
    end
    return __assignprops(
        struct_type,   # type being defined
        ap,            # assigned properties
        af,            # assigned fields
        nf,            # nested fields
        op,            # optional properties
        de_field,      # dictextension field
        pf
   )
end

macro assignprops(ex, kwdefs...)
    _assignprops(ex, kwdefs...)
end
