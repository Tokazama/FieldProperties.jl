using FieldProperties, Test

mutable struct MyProperties{M} <: AbstractMetadata{M}
    my_description::String
    my_properties::M
end

@assignprops(
    MyProperties,
    :my_description => description,
    :my_properties => dictextension)

m = MyProperties("", Dict{Symbol,Any}())

@testset "Property interface" begin
    @test propname(description) == :description

    @test propdefault(description) == FieldProperties.not_property
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

@testset "DictExtension{:dictproperty}::AbstractDict{Symbol}" begin
    # Note: we don't have specifiers on these so we can't expect inferrible types
    m.foo = ""
    @test m.foo == ""

    @test_throws ErrorException("type MyProperties does not have property bar") getproperty(m, :bar)
end

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
    :my_properties => dictextension(calmax,calmin))

@testset "Optional properties" begin
    A = MyArray(rand(4,4), Dict{Symbol,Any}());

    @test FieldProperties.calmax(A) == maximum(A)
    @test A.calmax == maximum(A)

    new_calmax = Float32((maximum(A) - minimum(A)) / 2)
    A.calmax = new_calmax
    @test A.calmax == new_calmax
    @test A.calmax isa eltype(A)
    @test FieldProperties.calmax(A) == new_calmax
end
