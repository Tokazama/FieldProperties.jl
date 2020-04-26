
_property(ex::Symbol) = PropertyGenerator(ex)


get_propname(ex::Symbol) = ex
function get_propname(ex::Expr)
    if ex.head === :(::)
        return get_propname(ex.args[1]))
    elseif ex.head === :call
        return get_propname(ex.args[1])
    end
end

get_propargs(ex::Symbol) = esc(:self), esc(:val)
function get_propargs(ex::Expr)
    if ex.head === :(::)
        return get_propname(ex.args[1]))
    elseif ex.head === :call
        if length(ex.args) == 1
            return esc(:self), esc(:val)
        elseif length(ex.args) == 2
            return esc(x.args[2]), esc(:val)
        else
            return esc(x.args[2]), esc(x.args[3])
        end
    end
end

is_getter_call(x::Expr) = x.head === :(->)
is_getter_call(x) = false

is_setter_call(x::Expr) = x.head === :(-->)
is_setter_call(x) = false

function get_proptype(ex::Expr)
    if ex.head === :(::)
        return esc(ex.args[2])
    else
        return nothing
    end
end

function get_getproperty(getname, pname, self, blk::Expr)
    get_expr = callexpr(dotexpr(:FieldProperties, :propconvert),
                        getname,
                        self,
                        callexpr(esc(:getproperty), self, QuoteNode(pname)))
    for line_i in blk.args
        if is_getter_call(line_i)
            get_expr = fxnbody(line_i)
        end
    end
    return fxnexpr(callexpr(getname, self), get_expr)
end

function get_setproperty(setname, getname, pname, self, val, blk::Expr)
    set_expr = callexpr(esc(:setproperty!),
                        self,
                        QuoteNode(pname),
                        callexpr(dotexpr(:FieldProperties, :propconvert), getname, self, val))
    for line_i in blk.args
        if is_setter_call(line_i)
            set_expr = fxnbody(line_i)
        end
    end
    return fxnexpr(callexpr(setname, self), set_expr)
end


function _property(ex, blk)
    pname = get_propname(ex)
    getname = esc(pname)
    setname = esc(Symbol(pname, :!))
    ptype = get_proptype(ex)
    self, val = get_propargs(pname, self, ex)
    setexpr = get_setproperty(setname, getname, pname, self, val, blk)
    getexpr = get_setproperty(getname, pname, self, blk)

    for line_i in blk.args
        if is_macro_expr(line_i)
            push!(out.args, macro_to_call(pname, line_i))
        end
    end

    push!(out.args, :(const $getname = $struct_name{$(esc(:getproperty))}()))
    push!(out.args, :(const $setname = $struct_name{$(esc(:setproperty!))}()))


    return :(struct $(struct_name){$(esc(:T))} <: $(dotexpr(:FieldProperties, :AbstractProperty)){$(QuoteNode(pname)),$(esc(:T))} end), out
end

_property(ex) = _property(ex, Expr(:block))


"""
    @property


```jldoctest
@macroexpand @property prop1

@macroexpand @property prop2::Int

@macroexpand @property prop2::(x -> eltype(x)) x =>
```
"""
macro property(expr)
    expr = macroexpand(__module__, expr)

    getexpr, setexpr, typeexpr = _property(expr)
    quote
        Base.@__doc__($(getexpr))
        $setexpr
        $typeexpr
    end
end

macro property(expr, blk)
    expr = macroexpand(__module__, expr)

    getexpr, setexpr, typeexpr = _property(expr, blk)
    quote
        Base.@__doc__($(getexpr))
        $setexpr
        $typeexpr
    end
end

#=
    # get property defaults
    if x isa Expr && x.head === :(=)
        if x.args[2] isa Expr && x.args[2].head == :->
            default_arg = esc(x.args[2].args[1])
            default = esc(x.args[2].args[2])
            x2 = x.args[1]
        else # TODO don't know what to do here
            default_arg = default = nothing
            x2 = x
        end
    else
        default_arg = default = nothing
        x2 = x
    end

    # get property type enforcement
    if x2 isa Expr && x2.head === :(::)
        if x2.args[2] isa Expr && x2.args[2].head == :->
            ptype_arg = esc(x2.args[2].args[1])
            ptype = esc(x2.args[2].args[2])
            getname = x2.args[1]
        else
            ptype_arg = esc(:x)
            ptype = esc(x2.args[2])
            getname = x2.args[1]
        end
    else
        ptype = nothing
        ptype_arg = esc(:x)
        getname = x2
    end
    setname = esc(Symbol(getname, :!))
    pname = QuoteNode(getname)
    getname = esc(getname)
    blk = Expr(:block)
    push!(blk.args, Expr(:function,
                         callexpr(setname, esc(:x), esc(:val)),
                         callexpr(esc(:setproperty!),
                                  esc(:x),
                                  pname,
                                  callexpr(dotexpr(:FieldProperties, :propconvert),
                                           getname,
                                           esc(:x),
                                           esc(:val)))))
    if isnothing(default)
        getfxn = fxnexpr(callexpr(getname, esc(:x)),
                         callexpr(dotexpr(:FieldProperties, :propconvert),
                                  getname,
                                  esc(:x),
                                  callexpr(esc(:getproperty),
                                           esc(:x),
                                           pname)))
    else
        getfxn = fxnexpr(callexpr(getname, default_arg), default)
    end
    if !isnothing(ptype)
        push!(blk.args, fxnexpr(callexpr(dotexpr(:FieldProperties, :proptype),
                                         Expr(:(::), Expr(:call, esc(:typeof), getname)),
                                         ptype_arg),
                                ptype))
    end

end
=#


"""
    AbstractMetadata
"""
abstract type AbstractMetadata{D<:AbstractDict{Symbol,Any}} <: AbstractDict{Symbol,Any} end

Base.empty!(m::AbstractMetadata) = empty!(dictextension(m))

function Base.get(m::AbstractMetadata, p, default)
    if hasproperty(m, p)
        return getproperty(m, p)
    else
        return default
    end
end

function Base.get!(m::AbstractMetadata, k, default)
    if hasproperty(m, p)
        return getproperty(m, p)
    else
        setproperty!(m, p, default)
        return default
    end
end

# TODO
#Base.in(k, m::AbstractMetadata) = in(k, propname(m))

#Base.pop!(m::AbstractMetadata, k) = pop!(dictextension(m), k)

#Base.pop!(m::AbstractMetadata, k, default) = pop!(dictextension(m), k, default)

Base.isempty(m::AbstractMetadata) = isempty(dictextension(m))

Base.delete!(m::AbstractMetadata, k) = delete!(dictextension(m), k)

@inline Base.getindex(x::AbstractMetadata, s::Symbol) = getindex(dictextension(x), s)

@inline function Base.setindex!(x::AbstractMetadata, val, s::Symbol)
    return setindex!(dictextension(x), val, s)
end

Base.length(m::AbstractMetadata) = length(propertynames(m))

Base.getkey(m::AbstractMetadata, k, default) = getkey(dictextension(m), k, default)

Base.keys(m::AbstractMetadata) = propertynames(m)

suppress(m::AbstractMetadata) = get(m, :suppress, ())

Base.show(io::IO, m::AbstractMetadata) = showdictlines(io, m, suppress(m))
Base.show(io::IO, ::MIME"text/plain", m::AbstractMetadata) = showdictlines(io, m, suppress(m))
function showdictlines(io::IO, m, suppress)
    print(io, summary(m))
    for (k, v) in m
        if !in(k, suppress)
            print(io, "\n    ", k, ": ")
            print(IOContext(io, :compact => true), v)
        else
            print(io, "\n    ", k, ": <suppressed>")
        end
    end
end

#Base.iterate(m::AbstractMetadata, state=1) = _iterate_properties(m, state)

"""
    NoopMetadata

Empty dictionary that indicates there is no metadata.
"""
struct NoopMetadata <: AbstractMetadata{Dict{Symbol,Any}} end

Base.isempty(::NoopMetadata) = true

Base.get(::NoopMetadata, k, default) = default

Base.length(::NoopMetadata) = 0

Base.haskey(::NoopMetadata, k) = false

Base.in(k, ::NoopMetadata) = false

Base.propertynames(::NoopMetadata) = ()

Base.iterate(m::NoopMetadata) = nothing

Base.iterate(m::NoopMetadata, state) = nothing

function Base.setindex!(m::NoopMetadata, val, s::Symbol)
    error("Cannot set property for NoopMetadata.")
end

"""
    Metadata{D}

Subtype of `AbstractMetadata` that provides `getproperty` syntax for accessing
the values of a dictionary.
"""
struct Metadata{D} <: AbstractMetadata{D}
    dictextension::D
end

function Metadata(; kwargs...)
    out = Metadata(Dict{Symbol,Any}())
    for (k,v) in kwargs
        out[k] = v
    end
    return out
end

@properties Metadata begin
    Any(self) -> (dictextension)
    Any!(self, val) -> (dictextension)
end

Base.iterate(m::Metadata) = iterate(getfield(m, :dictextension))
Base.iterate(m::Metadata, state) = iterate(getfield(m, :dictextension), state)

