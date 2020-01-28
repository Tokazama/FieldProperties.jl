using FieldProperties: set_dictextension_property!

@testset "dictextension" begin
    @test set_dictextension_property!(m, :testprop, 1)
    @test set_dictextension_property!(MultiNest(Nested1(1,2),Nested2(3,4)), :testprop, 1) == false
end
