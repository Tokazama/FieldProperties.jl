function _defprop(d, t, name::Symbol, struct_name::Expr)
    sym_name = QuoteNode(name)
    getter_fxn = esc(name)
    setter_fxn = esc(Symbol(name, :!))
    T = esc(:T)

    blk = Expr(:block)
    push!(blk.args, :(const $getter_fxn = $struct_name{FieldProperties.Getter}()))
    push!(blk.args, :(const $setter_fxn = $struct_name{FieldProperties.Setter}()))
    push!(blk.args, :(FieldProperties.get_setter(::Type{<:$struct_name}) = $setter_fxn))
    push!(blk.args, :(FieldProperties.get_getter(::Type{<:$struct_name}) = $getter_fxn))
    _add_propdefault!(blk, d, struct_name)
    _add_proptype!(blk, t, struct_name)
    return :(struct $(struct_name){$T} <: FieldProperties.AbstractProperty{$sym_name,$T} end), blk
end

_defprop(d, t, name::QuoteNode, struct_name::Symbol) = _defprop(d, t, name.value, esc(struct_name))

function _defprop(x, d, t)
    if x.head === :curly
        return _defprop(d, t, x.args[2], x.args[1])
    else
        error("properties must atleast have be of form PropertyType{:property_name}.")
    end
end
 
function _defprop(x, d)
    if x.head === :(::)
        if x.args[2] isa Expr && x.args[2].head == :->
            return _defprop(x.args[1], d, (x.args[2].args[1], x.args[2].args[2]))
        else
            return _defprop(x.args[1], d, x.args[2])
        end
    else
        return _defprop(x, d, nothing)
    end
end

function _defprop(x)
    if x.head === :(=)
        if x.args[2] isa Expr && x.args[2].head == :->
            return _defprop(x.args[1], (x.args[2].args[1], x.args[2].args[2]))
        else
            return _defprop(x.args[1], x.args[2])
        end
    else
        return _defprop(x, nothing)
    end
end

_add_propdefault!(blk::Expr, ::Nothing, const_type) = nothing
function _add_propdefault!(blk::Expr, expr, const_type)
    if expr isa Tuple
        push!(blk.args, :(FieldProperties.propdefault(::Type{<:$const_type}, $(esc(expr[1]))) = $(esc(expr[2]))))
    else
        push!(blk.args, :(FieldProperties.propdefault(::Type{<:$const_type}, $(esc(:x))) = $(esc(expr))))
    end
end

_add_proptype!(blk::Expr, ::Nothing, const_type) = nothing
function _add_proptype!(blk::Expr, expr, const_type)
    if expr isa Tuple
        push!(blk.args, :(FieldProperties.proptype(::Type{<:$const_type}, $(esc(expr[1]))) = $(esc(expr[2]))))
    else
        push!(blk.args, :(FieldProperties.proptype(::Type{<:$const_type}, $(esc(:x))) = $(esc(expr))))
    end
end


"""
    @defprop

## Examples
```jldoctest propexamples
julia> @defprop Property1{:prop1}

julia> propname(prop1)
:prop1

julia> propdefault(prop1)
NotProperty

julia> propdefault(prop11)
NotProperty

julia> proptype(prop11)
Any
```

Define the propertie's type
```jldoctest propexamples
julia> @defprop Property2{:prop2}::Int

julia> propname(prop2)
:prop2

julia> propdefault(prop2)
NotProperty

julia> proptype(prop2) == Int
true

```

Define type requirement and default value.
```jldoctest propexamples
julia> @defprop Property3{:prop3}::Int=1

julia> propname(prop3)
:prop3

julia> propdefault(prop3)
1

julia> proptype(prop3)
Int
```

Define a default value but no type requirement.
```jldoctest propexamples
julia> @defprop Property4{:prop4}=1

julia> propname(prop4) == :prop4
true

julia> propdefault(prop4) == 1
true

julia> proptype(prop4) == Any
true
```

Default type and default values for the property can be defined by functions
```jldoctest propexamples
julia> @defprop Property5{:prop5}::(x -> eltype(x))= x -> maximum(x)
```
"""
macro defprop(expr)
    expr = macroexpand(__module__, expr)
    PropertyStruct, blk = _defprop(expr)
    quote
        Base.@__doc__($(PropertyStruct))
        $blk
    end
end
