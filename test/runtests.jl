using FieldProperties, Test, Documenter

struct TestStruct
    p1
    p2
    p3
    p4
end

@properties TestStruct begin
    prop1(self) => :p1
    prop2(self) => :p2
    prop3(self) => :p3
    prop4(self) => :p4
end

t = TestStruct(1,2,3,4)

@test propertynames(t) == (:prop1,:prop2,:prop3,:prop4)


x = rand(4,4)
@test @inferred(calmin(x)) == minimum(x)
@test @inferred(calmax(x)) == maximum(x)

include("metadata_tests.jl")

@testset "FieldProperties docs" begin
    doctest(FieldProperties; manual=false)
end


#=
include("macro_composability.jl")
include("properties_tests.jl")

mutable struct MyProperties{M} <: AbstractMetadata{M}
    my_description::String
    my_properties::M
end

@properties MyProperties begin
    description => :my_description
    Any => (:my_properties)
end

m = MyProperties("", Dict{Symbol,Any}())

mutable struct Nested1
    field1
    field2
end

mutable struct Nested2
    field3
    field4
end

struct MultiNest{F1,F2}
    field1::F1
    field2::F2
end

@assignprops(
    MultiNest,
    :field1 => nested,
    :field2 => nested
)

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
    @test propdoclist(MyProperties) == "* description: Description that may say whatever you like.\n"
end

@testset "setter!(x, p::NotProperty, s::Symbol, val)" begin
    # Note: we don't have specifiers on these so we can't expect inferrible types
    m.foo = ""
    @test m.foo == ""

    @test_throws ErrorException("type MyProperties does not have property bar") getproperty(m, :bar)
end

@testset "setter!(x, p::AbstractProperty, ::Nothing, val)" begin
    m = Metadata()
    calmax!(m, 2)
    @test calmax(m) == 2
end
=#


#=
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

@properties MyArray begin
    calmin => :my_calmin
    Any(self) => :my_properties
    Any!(self, val) => :my_properties
end

#get_flag(x, p) = first(getter(x, p))
#nested_get_flag(x) = first(getter(x, :calmax))
@testset "Optional properties" begin
    a = rand(4,4);
    my_min = (maximum(a) - minimum(a)) / 2
    my_a = MyArray(a, my_min, Dict{Symbol,Any}());

    @test @inferred(proptype(calmax, my_a)) <: eltype(a)
    #@test @inferred(get_flag(my_a, calmax)) == calmax
    #@test @inferred(nested_get_flag(my_a)) == calmax
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
=#
