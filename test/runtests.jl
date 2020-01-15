using MetadataUtils, Test

using MetadataUtils: description, description!

mutable struct MyProperties{M} <: AbstractMetadata{M}
    my_description::String
    my_properties::M
end

@assignprops(
    MyProperties,
    :my_description => Description,
    :my_properties => DictExtension)

m = MyProperties("", Dict{Symbol,Any}())

@testset "Property interface" begin
    @test getproperty(Description, :getter) == description
    @test getproperty(Description, :setter) == description!
    @test_throws ErrorException getproperty(Description, :bar)

    @test propertynames(Description) == (:getter, :setter)

    @test property(Description) == Description
    @test property(description) == Description
    @test property(description!) == Description

    @test propname(Description) == :description
    @test propname(description) == :description

    @test propdefault(description) == NotProperty
    @test proptype(description) <: String
end

@testset "@property Description{:description}::String" begin
    encapsulated_getproperty(x) = getproperty(x, :description)

    @test propertynames(m) == (:description,)
    @test @inferred(description(m)) == ""
    @test @inferred(encapsulated_getproperty(m)) == ""

    description!(m, "foo")
    @test @inferred(description(m)) == "foo"
    @test @inferred(encapsulated_getproperty(m)) == "foo"

    m.description = "bar"
    @test @inferred(description(m)) == "bar"
    @test @inferred(encapsulated_getproperty(m)) == "bar"
end

@testset "@property DictExtension{:dictproperty}::AbstractDict{Symbol}" begin
    # Note: we don't have specifiers on these so we can't expect inferrible types
    m.foo = ""
    @test m.foo == ""

    @test_throws ErrorException("type MyProperties does not have property bar") getproperty(m, :bar)
end

@defprop CalibrationMaximum{:calmax}
MetadataUtils.propdefault(::CalibrationMaximumType, x::AbstractArray) = maximum(x)
MetadataUtils.proptype(::Type{CalibrationMaximumType}, ::Type{<:AbstractArray{T,N}}) where {T,N} = T

@defprop CalibrationMinimum{:calmin}
MetadataUtils.propdefault(::CalibrationMinimumType, x::AbstractArray) = minimum(x)
MetadataUtils.proptype(::Type{CalibrationMinimumType}, ::Type{<:AbstractArray{T,N}}) where {T,N} = T

struct MyArray{T,N,P<:AbstractArray{T,N},M<:AbstractDict{Symbol,Any}} <: AbstractArray{T,N}
    _parent::P
    my_properties::M
end
Base.parent(m::MyArray) = getfield(m, :_parent)
Base.size(m::MyArray) = size(parent(m))
Base.maximum(m::MyArray) = maximum(parent(m))
Base.minimum(m::MyArray) = minimum(parent(m))


@assignprops(
    MyArray,
    :my_properties => DictExtension(CalibrationMaximum,CalibrationMinimum))

@testset "Optional properties" begin
    A = MyArray(rand(4,4), Dict{Symbol,Any}());

    @test calmax(A) == maximum(A)
    @test A.calmax == maximum(A)

    new_calmax = Float32((maximum(A) - minimum(A)) / 2)
    A.calmax = new_calmax
    @test A.calmax == new_calmax
    @test A.calmax isa eltype(A)
    @test calmax(A) == new_calmax
end
