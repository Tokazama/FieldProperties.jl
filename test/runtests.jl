using FieldProperties, Test
using FieldProperties: getter, setter!, propconvert

include("properties_tests.jl")

mutable struct MyProperties{M} <: AbstractMetadata{M}
    my_description::String
    my_properties::M
end

@assignprops(
    MyProperties,
    :my_description => description,
    :my_properties => dictextension)

m = MyProperties("", Dict{Symbol,Any}())

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

    @test propdoc(description) == "Description that may say whatever you like."
    @test propdoc(MyProperties) == (description = "Description that may say whatever you like.",)
end

@testset "DictExtension{:dictproperty}::AbstractDict{Symbol}" begin
    # Note: we don't have specifiers on these so we can't expect inferrible types
    m.foo = ""
    @test m.foo == ""

    @test_throws ErrorException("type MyProperties does not have property bar") getproperty(m, :bar)
end

struct MyArray{T,N,P<:AbstractArray{T,N},M<:AbstractDict{Symbol,Any}} <: AbstractArray{T,N}
    _parent::P
    my_calmin::T
    my_properties::M
end
Base.parent(m::MyArray) = getfield(m, :_parent)
Base.size(m::MyArray) = size(parent(m))
Base.maximum(m::MyArray) = maximum(parent(m))
Base.minimum(m::MyArray) = minimum(parent(m))
Base.getindex(m::MyArray, i...) = getindex(parent(m), i...)

@assignprops(
    MyArray,
    :my_calmin => calmin,
    :my_properties => dictextension(calmax))

get_flag(x, p) = first(getter(x, p))
nested_get_flag(x) = get_flag(x, :calmax)
@testset "Optional properties" begin
    a = rand(4,4);
    my_min = (maximum(a) - minimum(a)) / 2
    my_a = MyArray(a, my_min, Dict{Symbol,Any}());

    @test @inferred(proptype(calmax, my_a)) <: eltype(a)
    @test @inferred(get_flag(my_a, calmax)) == calmax
    @test @inferred(nested_get_flag(my_a)) == calmax
    @test @inferred(calmax(a)) == maximum(a)
    @test @inferred(calmax(my_a)) == maximum(a)
    @test my_a.calmax == maximum(a)

    @test @inferred(calmin(a)) == minimum(a)

    new_calmax = Float32((maximum(a) - minimum(a)) / 2)
    my_a.calmax = new_calmax
    @test my_a.calmax == new_calmax
    @test my_a.calmax isa eltype(my_a)
    @test calmax(my_a) == new_calmax
end



include("metadata_tests.jl")
