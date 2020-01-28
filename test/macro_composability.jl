
using FieldProperties: get_optional_properties_expr!, to_field_name, to_property_name, to_property, to_field_name

ex = :(:field => prop1)

@testset "to_property_name" begin
    @test to_property_name(:prop1) == :(($(Expr(:escape, :(FieldProperties.propname))))($(Expr(:escape, :prop1))))
    @test to_property_name(QuoteNode(:prop1)) == to_property_name(:prop1)
    @test to_property_name(ex) == to_property_name(:prop1)
end

@testset "to_property" begin
    @test to_property(:prop1) == :prop1
    @test to_property(QuoteNode(:prop1)) == :prop1
    @test to_property(ex) == :prop1
end

@testset "to_field_name" begin
    @test to_field_name(ex) == QuoteNode(:field)
    @test to_field_name(:field) == to_field_name(ex)
    @test to_field_name(QuoteNode(:field)) == to_field_name(ex)
end
