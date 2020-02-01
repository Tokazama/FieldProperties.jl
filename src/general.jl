# general properties that just need a home

"""
Description that may say whatever you like.
"""
@defprop Description{:description}::String

@defprop Status{:status}

@defprop Modality{:modality}

"""
Property providing label for parent structure.
"""
@defprop Label{:label}::Symbol

#=
"""
Property providing name for parent structure.
"""
@defprop Name{:name}::Symbol
=#

"""
Specifies maximum element for display purposes. If not specified returns the maximum value in the collection.
"""
@defprop CalibrationMaximum{:calmax}::(x::AbstractArray->eltype(x)) begin
    @getproperty x -> maximum(x)
end

"""
Specifies minimum element for display purposes. If not specified returns the minimum value in the collection.
"""
@defprop CalibrationMinimum{:calmin}::(x::AbstractArray->eltype(x)) begin
    @getproperty x -> minimum(x)
end


#=
x = :(calmax(x, val)::(eltype(x)) => begin
    x + 1
end <= begin
    x + 1
end)


Base.@kwdef mutable struct PropertyGenerator
    getcall::Union{Expr,Nothing}=nothing
    setcall::Union{Expr,Nothing}=nothing
    getbody::Union{Expr,Nothing}=nothing
    setbody::Union{Expr,Nothing}=nothing
    ptype::Union{Expr,Nothing}=nothing
    self::Expr=esc(:self)
    val::Expr=esc(:val)
end

function Base.setproperty!(p::PropertyGenerator, s::Symbol, val)
    if s === :getbody
        if isnothing(p.getbody)
            return setfield!(p, s, val)
        else
            error("Multiple arguments for getproperty provided.")
        end
    elseif s === :setbody
        if isnothing(p.getbody)
            return setfield!(p, s, val)
        else
            error("Multiple arguments for setproperty provided.")
        end
    end
    setfield!(p, s, val)
end

function _property(p, ex::Expr)
    if x.head == :call
        if x.args[1] == :(=>)
            setbody
        elseif x.args[1] == :(<=)
        else
        end
    elseif x.head == :(::)
    else
    end
end

function _property(p, ex::Expr)
end

function _property(p, ex::Symbol)
    p.getcall = esc(ex)
    p.setcall = esc(Symbol(ex, :!))
    return p
end

x = :(calmax::(eltype(x))::(x |> x + 1)::((x, val) -> x + 1))

x = :(calmax::(eltype(x)) |> x + 1 <| x.calmax = 1)


@macroexpand @property definition(self, val)::(eltype(self)) begin
end
=#
