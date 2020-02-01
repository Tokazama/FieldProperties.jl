fxnexpr(head, blk) = Expr(:function, head, blk)

function def_abstract_property_struct(pname, mname, body, args...)
    return fxnexpr(
        callexpr(
            Expr(:(::),
                Expr(:curly,
                     dotexpr(:FieldProperties, :AbstractProperty),
                     pname,
                     mname),
               ),
                args...),
        body
    )
end

function fxnhead(e::Expr)
    if (e.head === :(-->)) | (e.head === :->) | (e.head === :(=)) | (e.head === :function)
        return e.args[1]
    elseif e.head === :call
        if e.args[1] === :(=>)
            return e.args[2]
        end
    end
end

function fxnbody(e::Expr)
    if (e.head === :(-->)) | (e.head === :->) | (e.head === :(=)) | (e.head === :function)
        return e.args[2]
    elseif e.head === :call
        if e.args[1] === :(=>)
            return e.args[3]
        end
    end
end

function fxnop(e::Expr)
    if e.head === :call
        return e.args[1]
    else
        return e.head
    end
end

function check_for_setter(x::Symbol)
    xstring = string(x)
    xstart = Symbol(xstring[1:end-1])
    xlast = last(xstring)
    if xlast == '!'
        return true, xstart
    else
        return false, x
    end
end

# is_setter, self, val, property_symbol
function parse_head(e::Expr, oldself, oldval)
    prop = get_property(e)
    newval = get_val(e)
    newself = get_self(e)
    is_setter, property_symbol = check_for_setter(prop)
    self, val = check_args(newself, oldself, newval, oldval)
    return is_setter, self, val, property_symbol
end

function check_args(newself, oldself, newval, oldval)
    if isnothing(oldself)
        return newself, check_args(newval, oldval)
    else
        if newself === oldself
            return newself, check_args(newval, oldval)
        else
            error("Argument to referring to self is inconsistent, got $newself and $oldself.")
        end
    end
end

function check_args(newval, oldval)
    if isnothing(oldval)
        return newval
    else
        if isnothing(newval)
            return oldval
        else
            if oldval === newval
                return newval
            else
                error("Argument to referring to value is inconsistent, got $newval and $oldval.")
            end
        end
    end
end

# exract the property symbol
get_property(e::Symbol) = e
function get_property(e::Expr)
    if is_call(e)
        return get_property(first(e.args))
    elseif is_dotexpr(e)
        return get_property(last(e.args))
    end  # TODO nice error for not call
end
get_property(e::QuoteNode) = e.value

# extract the self referencing argument
function get_self(e::Expr)
    if is_call(e)
        if length(e.args) > 1
            return e.args[2]
        end  # TODO error for no call arguments
    end  # TODO nice error for not call
end

# extract the self referencing argument
function get_val(e::Expr)
    if is_call(e)
        if length(e.args) == 3
            return e.args[3]
        else
            return nothing
        end
    end  # TODO nice error for not call
end

function is_dotexpr(e::Expr)
    if is_call(e)
        return is_dotexpr(e.args[1])
    else
        return e.head === :.
    end
end

dotexpr(root::Symbol, property::Symbol) = dotexpr(root, QuoteNode(property))
dotexpr(root::Symbol, property::QuoteNode) = esc(Expr(:., root, property))

function dotparse(e::Expr)
    if is_call(e)
        return dotparse(e.args[1])
    elseif is_dotexpr(e)
        return _dotparse(e.args[1], e.args[2])
    end
end
_dotparse(lhs, rhs::Symbol) = lhs, rhs
_dotparse(lhs, rhs::QuoteNode) = lhs, rhs.value

var(x::Symbol) = esc(x)
var(x::Symbol, vartype) = var(esc(x), vartype)
var(x::Expr, vartype) = _var(x, vartype)
_var(x, vartype::Symbol) = _var(x, esc(vartype))
function _var(x, vartype::Expr)
    if vartype.head === :escape
        return Expr(:(::), x, vartype)
    else
        return _var(x, esc(vartype))
    end
end

callexpr(x, args...) = Expr(:call, x, args...)

is_call(e::Expr) = e.head === :call
is_call(e) = false

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

is_macro_expr(x::Expr) = x.head === :macrocall
is_macro_expr(x) = false

get_macro_symbol(x) = Symbol(string(x.args[1])[2:end])

function macro_to_call(pname::QuoteNode, expr)
    method_name = get_macro_symbol(expr)
    args = []
    body = Expr(:block)
    for line_i in expr.args[2:end]
        if line_i isa LineNumberNode
            continue
        else
            body = esc(fxnbody(line_i))
            head = fxnhead(line_i)

            if head isa Symbol
                args = [esc(head)]
            elseif head isa Expr
                if head.head == :(::)
                    args = [esc(head)]
                else
                    args = esc.(head.args)
                end
            end
        end
    end
    return def_abstract_property_struct(pname.value, esc(method_name), body, args...)
end

_type(T) = Expr(:(::), Expr(:curly, esc(:Type), Expr(:(<:), T)))
