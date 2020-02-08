"""

    @properties T block

Syntactic sugar for custom `getproperty`, `setproperty!`, and `propertynames` methods.
For any type `T` passed to `@properties` these methods will be rewritten from their default.

## Examples

The following syntax assigns property names to function calls.
```jldoctest properties
julia> using FieldProperties

julia> mutable struct MyType
           x::Int
       end

julia> @properties MyType begin
           xint(self) = getfield(self, :x)
           xint!(self, val) = setfield!(self, :x, val)
           hello(self) = "hello"
       end

julia> mt = MyType(1)
MyType(1)

julia> mt.xint
1

julia> mt.xint = 2
2

julia> mt.xint
2

julia> mt.hello
"hello"

julia> propertynames(mt)
(:xint, :hello)

julia> mt.x
ERROR: Property x not found
[...]
```
There are three things you should take away from this:
1. `getproperty`, `setproperty!`, and `propertynames` are completely overwritten here
2. Any property assignment that ends with `!` is used to assign a `setproperty!`
3. `MyType` not longer can access the `x` field via `mt.x` (because of the first point).

It can be somewhat tedious to write out every `getfield` and `setfield` method, so let's redo this using `=>` to assign fields
```jldoctest properties
julia> @properties MyType begin
           xint(self) => :x
           xint!(self, val) => :x
           hello(self) = "hello"
       end

julia> mt = MyType(1)
MyType(1)

julia> mt.xint
1

julia> mt.xint = 2
2

julia> mt.xint
2

julia> mt.hello
"hello"

julia> propertynames(mt)
(:xint, :hello)

julia> mt.x
ERROR: Property x not found
[...]
```

Sometimes we want to use a modular approach to constructing a type. The following example requires users to know where to find the `x1`, `x2`, and `x3` fields.
```jldoctest properties
julia> mutable struct PropList1
           x2::Int
       end

julia> mutable struct PropList2
           x3::Int
       end

julia> mutable struct MyProperties
           x1::Int
           l1::PropList1
           l2::PropList2
       end

julia> mp = MyProperties(1, PropList1(2), PropList2(3))
MyProperties(1, PropList1(2), PropList2(3))

julia> mp.x1
1

julia> mp.l1.x2  # obnoxious for users
2

julia> mp.l2.x3  # also obnoxious for users
3
```

The following syntax tells our property methods to search through nested fields.
```jldoctest properties
julia> @properties MyProperties begin
           x1(self) => :x1
           x1!(self, val) => :x1
           Any(self) => (:l1, :l2)
           Any!(self, val) => (:l1, :l2)
       end

julia> propertynames(mp)
(:x1, :x2, :x3)

julia> mp.x1
1

julia> mp.x2
2

julia> mp.x3
3
```
The last two methods (`Any(x)` and `Any!(x, val)`) tell the `getproperty` and `setproperty!` methods search the `l1` and `l2` fields for any property that isn't `:x1`.

The lowered code is:
```julia
julia> @macroexpand @properties MyProperties begin
                  x1(self) => :x1
                  x1!(self, val) => :x1
                  Any(self) => (:l1, :l2)
                  Any!(self, val) => (:l1, :l2)
              end
quote
    function Base.getproperty(self::MyProperties, p::Symbol)
        if p === :x1
            getfield(self, :x1)
        else
            if hasproperty(getfield(self, :l1), p)
                getproperty(getfield(self, :l1), p)
            else
                getproperty(getfield(self, :l2), p)
            end
        end
    end
    function Base.setproperty!(self::MyProperties, p::Symbol, val)
        if p === :x1
            setfield!(self, :x1, val)
        else
            if hasproperty(getfield(self, :l1), p)
                setproperty!(getfield(self, :l1), p, val)
            else
                setproperty!(getfield(self, :l2), p, val)
            end
        end
    end
    function Base.propertynames(self::MyProperties)
        (:x1, propertynames(getfield(self, :l1))..., propertynames(getfield(self, :l2))...)
    end
end
```
Note that the the `:l1` and `l2` fields are searched in the same order they are called inside the macro (e.g., `Any(x) => (:l1, :l2)` results in searching `:l1` then `:l2`).

"""
macro properties(T, lines)
    blk = Expr(:block)

    nested_names = []
    property_names = []

    nested_setter_blk = Expr(:if)
    nested_getter_blk = Expr(:if)
    setter_blk = Expr(:if)
    getter_blk = Expr(:if)
    self = nothing
    val = nothing
    for line_i in lines.args
        if line_i isa LineNumberNode
            continue
        else
            head = fxnhead(line_i)
            body = fxnbody(line_i)
            op = fxnop(line_i)
            is_setter, self, val, prop_symbol = parse_head(head, self, val)
            if (op === :->) | (op === :(=)) | (op === :function)
                cnd = callexpr(:(===), esc(:p), QuoteNode(prop_symbol))
                if is_setter
                    chain_ifelse!(setter_blk, cnd, esc(body))
                else
                    chain_ifelse!(getter_blk, cnd, esc(body))
                end
                if !in(QuoteNode(prop_symbol), property_names)
                    push!(property_names, QuoteNode(prop_symbol))
                end
            elseif op === :(=>)
                if prop_symbol == :Any
                    if body isa QuoteNode
                        if is_setter
                            nested_setter_blk = callexpr(esc(:setproperty!), callexpr(esc(:getfield), esc(self), body), esc(:p), esc(val))
                        else
                            nested_getter_blk = callexpr(esc(:getproperty), callexpr(esc(:getfield), esc(self), body), esc(:p))
                        end
                        !in(body, nested_names) && push!(nested_names, body)
                    elseif body isa Symbol
                        if is_setter
                            nested_setter_blk = callexpr(esc(:setproperty!), callexpr(esc(:getfield), esc(self), QuoteNode(body)), esc(:p), esc(val))
                        else
                            nested_getter_blk = callexpr(esc(:getproperty), callexpr(esc(:getfield), esc(self), QuoteNode(body)), esc(:p))
                        end
                        !in(body, nested_names) && push!(nested_names, body)
                    elseif body isa Expr && body.head == :tuple
                        body = body.args
                        n = length(body)
                        for (i,n_i) in enumerate(body)
                            if is_setter
                                if i != n
                                    chain_ifelse!(
                                        nested_setter_blk,
                                        callexpr(esc(:hasproperty), callexpr(esc(:getfield), esc(self), n_i), esc(:p)),
                                        callexpr(esc(:setproperty!), callexpr(esc(:getfield), esc(self), n_i), esc(:p), esc(val))
                                    )
                                else
                                    final_out!(nested_setter_blk,
                                        callexpr(esc(:setproperty!), callexpr(esc(:getfield), esc(self), n_i), esc(:p), esc(val))
                                    )
                                end
                            else
                                if i != n
                                    chain_ifelse!(
                                        nested_getter_blk,
                                        callexpr(esc(:hasproperty), callexpr(esc(:getfield), esc(self), n_i), esc(:p)),
                                        callexpr(esc(:getproperty), callexpr(esc(:getfield), esc(self), n_i), esc(:p))
                                    )
                                else
                                    final_out!(nested_getter_blk,
                                        callexpr(esc(:getproperty), callexpr(esc(:getfield), esc(self), n_i), esc(:p))
                                    )
                                end
                            end
                            !in(n_i, nested_names) && push!(nested_names, n_i)
                        end
                    end
                else
                    cnd = callexpr(:(===), esc(:p), QuoteNode(prop_symbol))
                    body isa QuoteNode || error("shortand property assignments should take the form `property_name => :fieldname`, got $(typeof(body)) for field name.")
                    if is_setter
                        chain_ifelse!(setter_blk, cnd, callexpr(esc(:setfield!), esc(self), body, esc(val)))
                    else
                        chain_ifelse!(getter_blk, cnd, callexpr(esc(:getfield), esc(self), body))
                    end
                    if !in(QuoteNode(prop_symbol), property_names)
                        push!(property_names, QuoteNode(prop_symbol))
                    end
                end
            end
        end
    end

    if isempty(getter_blk.args)
        if !isempty(nested_getter_blk.args)
            push!(blk.args, Expr(:function, callexpr(dotexpr(:Base, :getproperty), var(self, T), var(:p, :Symbol)), nested_getter_blk))
        end
    else
        if isempty(nested_getter_blk.args)
            final_out!(getter_blk, callexpr(esc(:error), "Property ", esc(:p), " not found"))
        else
            final_out!(getter_blk, nested_getter_blk)
        end
        push!(blk.args, Expr(:function, callexpr(dotexpr(:Base, :getproperty), var(self, T), var(:p, :Symbol)), getter_blk))
    end

    if isempty(setter_blk.args)
        if !isempty(nested_setter_blk.args)
            push!(blk.args, Expr(:function, callexpr(dotexpr(:Base, :setproperty!), var(self, T), var(:p, :Symbol), esc(val)), nested_setter_blk))
        end
    else
        if isempty(nested_setter_blk.args)
            final_out!(setter_blk, callexpr(esc(:error), "Property ", esc(:p), " not found"))
        else
            final_out!(setter_blk, nested_setter_blk)
        end
        push!(blk.args, Expr(:function, callexpr(dotexpr(:Base, :setproperty!), var(self, T), var(:p, :Symbol), esc(val)), setter_blk))
    end

    # handle propertynames
    for nested_names_i in nested_names
        push!(property_names, Expr(:..., callexpr(esc(:propertynames), callexpr(esc(:getfield), esc(self), nested_names_i))))
    end
    push!(blk.args, Expr(:function, callexpr(dotexpr(:Base, :propertynames), var(self, T)), Expr(:tuple, property_names...)))
    return blk
end

