# general properties that just need a home

"""
Description that may say whatever you like.
"""
@defprop Description{:description}::String

@defprop Status{:status}::Bool

@defprop Modality{:modality}

@defprop Label{:label}


"""
Specifies maximum element for display purposes. If not specified returns the maximum value in the collection.
"""
@defprop CalibrationMaximum{:calmax}
MetadataUtils.propdefault(::CalibrationMaximumType, x::AbstractArray) = maximum(x)
MetadataUtils.proptype(::Type{CalibrationMaximumType}, ::Type{<:AbstractArray{T,N}}) where {T,N} = T

"""
Specifies minimum element for display purposes. If not specified returns the minimum value in the collection.
"""
@defprop CalibrationMinimum{:calmin}
MetadataUtils.propdefault(::CalibrationMinimumType, x::AbstractArray) = minimum(x)
MetadataUtils.proptype(::Type{CalibrationMinimumType}, ::Type{<:AbstractArray{T,N}}) where {T,N} = T

