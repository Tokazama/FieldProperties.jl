
function _defprop(t, name::Symbol, struct_name::Expr, blk)
    sym_name = QuoteNode(name)
    getter_fxn = esc(name)
    setter_fxn = esc(Symbol(name, :!))
    eltyper_fxn = esc(Symbol(name, :_type))
    T = esc(:T)

    out = quote
        @doc @doc($struct_name) ->
        const $getter_fxn = $struct_name{$(esc(:getproperty))}()

        @doc @doc($struct_name) ->
        const $setter_fxn = $struct_name{$(esc(:setproperty!))}()

        const $eltyper_fxn = $struct_name{$(esc(:eltype))}()

        (::$struct_name)($(esc(:f))::$(esc(:Function))) = $struct_name{$(esc(:f))}()
    end

    if !isnothing(t)
        if t isa Tuple
            push!(out.args, fxnexpr(callexpr(Expr(:(::), Expr(:curly, dotexpr(:FieldProperties, :AbstractProperty), sym_name, esc(:eltype))), esc(t[1])), esc(t[2])))
        else
            push!(out.args, fxnexpr(callexpr(Expr(:(::), Expr(:curly, dotexpr(:FieldProperties, :AbstractProperty), sym_name, esc(:eltype))), esc(:x)), esc(t)))
        end
    end

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

"""
    @defprop Property{name}::Type block

Convient way of creating properties that wrap `getproperty` and `setproperty!` methods.
## Examples

The simplest form simply creates a getter and setter.
```jldoctest defprop
julia> using FieldProperties

julia> @defprop Property1{:prop1}

julia> name(prop1)
:prop1

julia> prop1_type(:any_type)
Any
```

Define the propertie's type
```jldoctest defprop
julia> @defprop Property2{:prop2}::Int

julia> name(prop2)
:prop2

julia> prop2_type(:any_type)
Int64
```

Define type requirement and default value.
```jldoctest defprop
julia> @defprop Property3{:prop3}::Int begin
           @getproperty x -> 1
       end

julia> name(prop3)
:prop3

julia> prop3_type(:any_type)
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

julia> name(prop4)
:prop4

julia> prop4_type(:any_type)
Any

julia> prop4(1)
1
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

