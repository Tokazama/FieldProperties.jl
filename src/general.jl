# general properties that just need a home

"""
Description that may say whatever you like.
"""
@defprop Description{:description}::String

@defprop Status{:status}::Bool

@defprop Modality{:modality}

"""
Property providing label for parent structure.
"""
@defprop Label{:label}::Symbol

"""
Property providing name for parent structure.
"""
@defprop Name{:name}::Symbol

"""
Specifies maximum element for display purposes. If not specified returns the maximum value in the collection.
"""
@defprop CalibrationMaximum{:calmax}::(x->eltype(x))=x->maximum(x)

"""
Specifies minimum element for display purposes. If not specified returns the minimum value in the collection.
"""
@defprop CalibrationMinimum{:calmin}::(x->eltype(x))=x->minimum(x)
