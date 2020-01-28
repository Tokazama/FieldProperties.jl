

dotexpr(root::Symbol, property::Symbol) = dotexpr(root, QuoteNode(property))
dotexpr(root::Symbol, property::QuoteNode) = esc(Expr(:., root, property))

# for extracting the sides of operators
getrhs(e::Expr) = x.args[3]
getlhs(e::Expr) = x.args[2]
getoperator(e::Expr) = x.args[1]


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

iscall(e::Expr) = e.head === :call
iscall(e) = false

fxnexpr(head, blk) = Expr(:function, head, blk)
