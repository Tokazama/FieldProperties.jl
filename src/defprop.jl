
function create_getter_docs(name, const_name)
    "\t\t$name(x)\n\nReturns the  $(const_name.args[1]) property (see [`$(const_name.args[1])`](@ref))."
end

function create_setter_docs(name, const_name)
    "\t\t$(name)!(x, val)\n\nSets the  $(const_name.args[1]) property (see [`$(const_name.args[1])`](@ref))."
end

###
### @defprop
###
function _defprop(d, t, name::Symbol, const_name::Expr)
    sym_name = QuoteNode(name)
    getter_fxn = esc(name)
    setter_fxn = esc(Symbol(name, :!))
    d = esc(d)
    t = esc(t)
    x = esc(:x)
    val = esc(:val)
    s = esc(:s)
    getter_docs = create_getter_docs(name, const_name)
    setter_docs = create_setter_docs(name, const_name)
    const_name_print = string(const_name.args[1])
    blk = quote
        @doc $getter_docs $getter_fxn($x) = MetadataUtils._getproperty($x, $const_name)

        @doc $setter_docs $setter_fxn($x, $val) = MetadataUtils._setproperty!($x, $const_name, $val)

        MetadataUtils.propdefault(::Type{MetadataUtils.Property{$sym_name}}, ::Type{C}) where {C} = $d

        MetadataUtils.proptype(::Type{MetadataUtils.Property{$sym_name}}, ::Type{C}) where {C} = $t

        function MetadataUtils._show_property(io, ::MetadataUtils.Property{$sym_name})
            print(io, $const_name_print)
        end

        function Base.getproperty(::MetadataUtils.Property{$sym_name}, $s::Symbol)
            if $s === :getter
                return $getter_fxn
            elseif $s === :setter
                return $setter_fxn
            else
                error("type $(P.name) has no field $s")
            end
        end
    end

    return :(const $(const_name) = MetadataUtils.Property{$(sym_name)}()), blk
end

_defprop(d, t, name::QuoteNode, const_name::Symbol) = _defprop(d, t, name.value, esc(const_name))

function _defprop(x, d, t)
    if x.head === :curly
        return _defprop(d, t, x.args[2], x.args[1])
    else
        error("properties must atleast have be of form PropertyType{:property_name}.")
    end
end
 
function _defprop(x, d)
    if x.head === :(::)
        return _defprop(x.args[1], d, x.args[2])
    else
        return _defprop(x, d, :Any)
    end
end

function _defprop(x)
    if x.head === :(=)
        return _defprop(x.args[1], x.args[2])
    else
        return _defprop(x, :(MetadataUtils.NotProperty))
    end
end

"""
    @defprop

## Examples
```jldoctest propexamples
julia> @defprop Property1{:prop1}

julia> propname(Property1) == :prop1
true

julia> propdefault(Property1)
NotProperty

julia> propdefault(Property1) == NotProperty
true

julia> proptype(Property1) == Any
true

julia> Property1.getter == prop1
true

julia> Property1.setter == prop1!
true
```

Define the propertie's type
```jldoctest propexamples
julia> @defprop Property2{:prop2}::Int

julia> propname(Property2) == :prop2
true

julia> propdefault(Property2) == NotProperty
true

julia> proptype(Property2) == Int
true

julia> Property2.getter == prop2
true

julia> Property2.setter == prop2!
true
```

Define type requirement and default value.
```jldoctest propexamples
julia> @defprop Property3{:prop3}::Int=1

julia> propname(Property3) == :prop3
true

julia> propdefault(Property3) == 1
true

julia> proptype(Property3) == Int
true
p

julia> Property3.getter == prop3
true

julia> Property3.setter == prop3!
true
```

Define a default value but no type requirement.
```jldoctest propexamples
julia> @defprop Property4{:prop4}=1

julia> propname(Property4) == :prop4
true

julia> propdefault(Property4) == 1
true

julia> proptype(Property4) == Any
true

julia> Property4.getter == prop4
true

julia> Property4.setter == prop4!
true
```
"""
macro defprop(expr)
    expr = macroexpand(__module__, expr)
    PropertyConst, blk = _defprop(expr)
    quote
        Base.@__doc__($(PropertyConst))
        $blk
    end
end
