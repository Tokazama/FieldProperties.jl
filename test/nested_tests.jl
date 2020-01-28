
@testset "nest properties" begin
    mn = MultiNest(Nested1(1,2), Nested2(3,4))

    @test @inferred(FieldProperties.has_dictextension(mn)) == false
    @test @inferred(FieldProperties.has_nested_fields(mn)) == true
    @test @inferred(FieldProperties.nested_fields(mn)) == (:field1, :field2)
    @test @inferred(FieldProperties.assigned_fields(mn)) == ()
    # we can't infer nested property names unless they are inferreable (which for some reason
    # they aren't for Nested1 and 2
    @test propertynames(mn) == (:field1, :field2, :field3, :field4)

    @test mn.field1 == 1
    @test mn.field2 == 2
    @test mn.field3 == 3
    @test mn.field4 == 4

    mn.field1 = 2
    @test mn.field1 == 2
end

