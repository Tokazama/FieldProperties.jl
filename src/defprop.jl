
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
    const_name_symbol = QuoteNode(const_name.args[1])

    const_type = esc(Symbol(const_name.args[1], :Type))

    blk1 = quote
        @doc $getter_docs $getter_fxn($x) = FieldProperties._getproperty($x, $const_name)

        @doc $setter_docs $setter_fxn($x, $val) = FieldProperties._setproperty!($x, $const_name, $val)

        const $const_type =  FieldProperties.Property{$sym_name,$getter_fxn,$setter_fxn}
    end
    blk2 = quote
        FieldProperties.propdefault(::Type{<:FieldProperties.Property{$sym_name,$getter_fxn,$setter_fxn}}, ::Type{C}) where {C} = $d

        FieldProperties.proptype(::Type{<:FieldProperties.Property{$sym_name,$getter_fxn,$setter_fxn}}, ::Type{C}) where {C} = $t

        function FieldProperties.propdoc(::Type{<:FieldProperties.Property{$sym_name,$getter_fxn,$setter_fxn}})
            return FieldProperties._extract_doc(Base.Docs.doc(Base.Docs.Binding($(@__MODULE__()), $(const_name_symbol))))
        end

        function FieldProperties._show_property(io, ::FieldProperties.Property{$sym_name,$getter_fxn,$setter_fxn})
            print(io, $const_name_print)
        end

        function FieldProperties.property(::Type{<:Union{typeof($getter_fxn),typeof($setter_fxn)}})
            return $const_name
        end
    end

    return :(const $(const_name) = $const_type()), blk1, blk2
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
        return _defprop(x, :(FieldProperties.NotProperty))
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
    PropertyConst, blk1, blk2 = _defprop(expr)
    quote
        $blk1
        Base.@__doc__($(PropertyConst))
        $blk2
    end
end
