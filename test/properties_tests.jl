@defprop Property1{:prop1}

@defprop Property2{:prop2}::Int

@defprop Property3{:prop3}::Int=1

@defprop Property4{:prop4}=1

@testset "Property interface" begin
    @test propname(prop1) == :prop1
    #@test propdefault(prop1) == NotProperty

    @test propname(prop2) == :prop2
    #@test propdefault(prop2) == NotProperty

    @test propname(prop3) == :prop3
    @test propdefault(prop3) == 1

    @test propname(prop4) == :prop4
    @test propdefault(prop4) == 1

    FieldProperties.propdefault(::Type{<:Property4}, ::AbstractString) = "1"
    FieldProperties.proptype(::Type{<:Property4}, ::AbstractString) = String

    @test prop4(2) == 1
    @test prop4("foo") == "1"

    @test propname(description) == :description
    @test propdefault(description) == FieldProperties.not_property
    @test proptype(description) <: String
end

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
    show(io, prop4)
    str = String(take!(io))
    @test str == "prop4 (generic function with 1 method)"

    io = IOBuffer()
    show(io, prop4!)
    str = String(take!(io))
    @test str == "prop4! (generic function with 1 method)"
end

prop4(::Nothing) = nothing
prop4!(::Nothing, val) = nothing
@testset "Print multiple methods" begin
    io = IOBuffer()
    show(io, prop4)
    str = String(take!(io))
    @test str == "prop4 (generic function with 2 methods)"

    io = IOBuffer()
    show(io, prop4!)
    str = String(take!(io))
    @test str == "prop4! (generic function with 2 methods)"
end
