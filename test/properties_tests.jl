@defprop Property1{:prop1}

@defprop Property2{:prop2}::Int

@defprop Property3{:prop3}::Int begin
    @getproperty x = 1
end

@defprop Property4{:prop4} begin 
    @getproperty x = 1
end

@testset "Property names" begin
    @test propname(prop1) == :prop1
    @test propname(prop2) == :prop2
    @test propname(prop3) == :prop3
    @test propname(prop4) == :prop4
    #@test propname(description) == :description
end

@testset "Property getproperty" begin

    @test prop3(3) == 1

    @test prop4(2) == 1

    (p::Property4{getproperty})(::AbstractString) = "1"
    FieldProperties.proptype(::Type{<:Property4}, ::AbstractString) = String
    @test prop4(2) == 1
    @test prop4("foo") == "1"
    #@test proptype(description) <: String
end

#=
@testset "get_[setter/getter]" begin
    @testset "No default type, No default value" begin
        @test FieldProperties.get_setter(prop1) == prop1!
        @test FieldProperties.get_setter(prop1!) == prop1!

        @test FieldProperties.get_getter(prop1) == prop1
        @test FieldProperties.get_getter(prop1!) == prop1
    end

    @testset "Default type, No default value" begin
        @test FieldProperties.get_setter(prop2) == prop2!
        @test FieldProperties.get_setter(prop2!) == prop2!

        @test FieldProperties.get_getter(prop2) == prop2
        @test FieldProperties.get_getter(prop2!) == prop2
    end

    @testset "Default type, Default value" begin
        @test FieldProperties.get_setter(prop3) == prop3!
        @test FieldProperties.get_setter(prop3!) == prop3!

        @test FieldProperties.get_getter(prop3) == prop3
        @test FieldProperties.get_getter(prop3!) == prop3
    end

    @testset "No default type, Default value" begin
        @test FieldProperties.get_setter(prop4) == prop4!
        @test FieldProperties.get_setter(prop4!) == prop4!

        @test FieldProperties.get_getter(prop4) == prop4
        @test FieldProperties.get_getter(prop4!) == prop4
    end
end
=#

@testset "proptype" begin
    @testset "No default type, No default value" begin
        @test proptype(prop1) <: Any
        @test proptype(typeof(prop1)) <: Any
        @test proptype(prop1!) <: Any
        @test proptype(typeof(prop1!)) <: Any
    end

    @testset "Default type, No default value" begin
        @test proptype(prop2) <: Int
        @test proptype(typeof(prop2)) <: Int
        @test proptype(prop2!) <: Int
        @test proptype(typeof(prop2!)) <: Int
    end

    @testset "Default type, Default value" begin
        @test proptype(prop3) <: Int
        @test proptype(prop3!) <: Int
    end

    @testset "No default type, Default value" begin
        @test proptype(prop4) <: Any
        @test proptype(prop4!) <: Any
    end
end

@testset "propconvert" begin
    @testset "No default type, No default value" begin
    end

    @testset "Default type, No default value" begin
    end

    @testset "Default type, Default value" begin
        @test typeof(propconvert(prop3, Int32(1))) == Int
    end

    @testset "No default type, Default value" begin
    end
end

@testset "Print single method" begin
    io = IOBuffer()
    show(io, not_property)
    str = String(take!(io))
    @test str == "not_property (generic function with 1 method)"
end

prop4(::Nothing) = nothing
prop4!(::Nothing, val) = nothing
@testset "Print multiple methods" begin
    io = IOBuffer()
    show(io, prop4)
    str = String(take!(io))
    @test str == "prop4 (generic function with $(length(methods(prop4))) methods)"

    io = IOBuffer()
    show(io, prop4!)
    str = String(take!(io))
    @test str == "prop4! (generic function with $(length(methods(prop4!))) methods)"
end


struct TestStruct
    p1
    p2
    p3
    p4
end

@properties TestStruct begin
    prop1 => :p1
    prop2 => :p2
    prop3 => :p3
    prop4 => :p4
end

t = TestStruct(1,2,3,4,5)

@test propertynames(t) == (:prop1,:prop2,:prop3,:prop4)
