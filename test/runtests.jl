using MetadataUtils, Test

using MetadataUtils: description, description!

mutable struct MyProperties{M} <: AbstractMetadata{M}
    my_description::String
    my_properties::M
end

MetadataUtils.subdict(m::MyProperties) = getfield(m, :my_properties)

@assignprops(
    MyProperties,
    :my_description => Description,
    :my_properties => DictProperty)

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

@testset "@property DictProperty{:dictproperty}::AbstractDict{Symbol}" begin
    # Note: we don't have specifiers on these so we can't expect inferrible types
    m.foo = ""
    @test m.foo == ""

    @test_throws ErrorException("type MyProperties does not have property bar") getproperty(m, :bar)
end

@defprop CalibrationMaximum{:calmax}
MetadataUtils.propdefault(::CalibrationMaximumType, x::AbstractArray) = maximum(x)
MetadataUtils.proptype(::CalibrationMaximumType, ::Type{<:AbstractArray{T,N}}) where {T,N} = T

@testset "propdefault" begin
    A = rand(2,2)
    @test calmax(A) == maximum(A)
end

