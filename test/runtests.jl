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
    @test @inferred(description(m)) == ""
    @test @inferred((() -> getproperty(m, :description))()) == ""

    description!(m, "foo")
    @test @inferred(description(m)) == "foo"
    @test @inferred((() -> getproperty(m, :description))()) == "foo"

    m.description = "bar"
    @test @inferred(description(m)) == "bar"
    @test @inferred((() -> getproperty(m, :description))()) == "bar"
end
