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
    @getproperty x::AbstractArray -> maximum(x)
end

"""
Specifies minimum element for display purposes. If not specified returns the minimum value in the collection.
"""
@defprop CalibrationMinimum{:calmin}::(x::AbstractArray->eltype(x)) begin
    @getproperty x::AbstractArray -> minimum(x)
end

