
function _defprop(t, name::Symbol, struct_name::Expr, blk)
    sym_name = QuoteNode(name)
    getter_fxn = esc(name)
    setter_fxn = esc(Symbol(name, :!))
    T = esc(:T)

    out = Expr(:block)
    push!(out.args, :(const $getter_fxn = $struct_name{$(esc(:getproperty))}()))
    push!(out.args, :(const $setter_fxn = $struct_name{$(esc(:setproperty!))}()))
    #_add_propdefault!(blk, d, struct_name)
    _add_proptype!(out, t, struct_name)

    for line_i in blk.args
        if is_macro_expr(line_i)
            push!(out.args, macro_to_call(QuoteNode(sym_name), line_i))
        end
    end

    return :(struct $(struct_name){$T} <: $(esc(Expr(:., :FieldProperties, QuoteNode(:AbstractProperty)))){$sym_name,$T} end), out
end

_defprop(t, name::QuoteNode, struct_name::Symbol, blk) = _defprop(t, name.value, esc(struct_name), blk)

function _defprop(x, t, blk)
    if x.head === :curly
        return _defprop(t, x.args[2], x.args[1], blk)
    else
        error("properties must atleast have be of form PropertyType{:property_name}.")
    end
end
 
function _defprop(x, blk)
    if x.head === :(::)
        if x.args[2] isa Expr && x.args[2].head == :->
            return _defprop(x.args[1], (x.args[2].args[1], x.args[2].args[2]), blk)
        else
            return _defprop(x.args[1], x.args[2], blk)
        end
    else
        return _defprop(x, nothing, blk)
    end
end

_add_proptype!(blk::Expr, ::Nothing, const_type) = nothing
function _add_proptype!(blk::Expr, expr, const_type)
    if expr isa Tuple
        push!(blk.args, fxnexpr(callexpr(dotexpr(:FieldProperties, :proptype), _type(const_type), esc(expr[1])), esc(expr[2])))
    else
        push!(blk.args, fxnexpr(callexpr(dotexpr(:FieldProperties, :proptype), _type(const_type), esc(:x)), esc(expr)))
    end
end


"""
    @defprop Property{name}::Type block

Convient way of creating properties that wrap `getproperty` and `setproperty!` methods.
## Examples

The simplest form simply creates a getter and setter.
```jldoctest defprop
julia> using FieldProperties

julia> @defprop Property1{:prop1}

julia> propname(prop1)
:prop1

julia> proptype(prop1)
Any

julia> prop1
prop1 (generic function with 1 method)

julia> prop1!
prop1! (generic function with 1 method)
```

Define the propertie's type
```jldoctest defprop
julia> @defprop Property2{:prop2}::Int

julia> propname(prop2)
:prop2

julia> proptype(prop2)
Int64
```

Define type requirement and default value.
```jldoctest defprop
julia> @defprop Property3{:prop3}::Int begin
           @getproperty x -> 1
       end

julia> propname(prop3)
:prop3

julia> proptype(prop3)
Int64

julia> prop3(3)
1
```

Define a default value but no enforced return type but multiple `getproperty` methods.
```jldoctest defprop
julia> @defprop Property4{:prop4} begin
           @getproperty x::Int -> 1
           @getproperty x::String -> "1"
       end

julia> propname(prop4)
:prop4

julia> proptype(prop4)
Any

julia> prop4(1)
1

julia> prop4
prop4 (generic function with 3 methods)

julia> prop4!
prop4! (generic function with 1 method)
```
"""
macro defprop(expr, blk)
    expr = macroexpand(__module__, expr)
    PropertyStruct, out = _defprop(expr, blk)
    quote
        Base.@__doc__($(PropertyStruct))
        $out
    end
end

macro defprop(expr)
    expr = macroexpand(__module__, expr)
    PropertyStruct, out = _defprop(expr, Expr(:block))
    quote
        Base.@__doc__($(PropertyStruct))
        $out
        nothing
    end
end

#=
x = :(@defprop Property3{:prop3}::Int begin
    @getproperty x = 1
end)
@defprop Property3{:prop3}::Int begin
    @getproperty x = 1
end
=#
