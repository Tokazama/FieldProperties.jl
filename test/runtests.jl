using MetadataUtils, Test

using MetadataUtils: description, description!

mutable struct MyProperties{M} <: AbstractMetadata{M}
    my_definition::String
    my_properties::M
end

MetadataUtils.subdict(m::MyProperties) = getfield(m, :my_properties)

@assignprops(
    MyProperties,
    :my_definition => Description,
    :my_properties => DictProperty)

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
end

@testset "@property DictProperty{:dictproperty}::AbstractDict{Symbol}" begin
    # Note: we don't have specifiers on these so we can't expect inferrible types
    m.foo = ""
    @test m.foo == ""

    @test_throws ErrorException("type MyProperties does not have property bar") getproperty(m, :bar)
end


