using FieldProperties, Test, Documenter

@testset "Print multiple methods" begin
    io = IOBuffer()
    show(io, description)
    str = String(take!(io))
    @test str == "description (generic function with 3 methods)"

    io = IOBuffer()
    show(io, description!)
    str = String(take!(io))
    @test str == "description! (generic function with $(length(methods(description!))) methods)"
end

FieldProperties.not_property() = nothing
@testset "Print single method" begin
    io = IOBuffer()
    show(io, FieldProperties.not_property)
    str = String(take!(io))
    @test str == "not_property(nothing) (generic function with 1 method)"
end

struct TestStruct
    p1
    p2
    p3
    p4
    p5
end

@properties TestStruct begin
    prop1(self) => :p1
    prop2(self) => :p2
    prop3(self) => :p3
    prop4(self) => :p4
    Any(self) => :p5
    Any!(self, val) => :p5
end

t = TestStruct(1,2,3,4,5)

@test propertynames(t) == (:prop1,:prop2,:prop3,:prop4)

FieldProperties._fxnname(FieldProperties.Description{values}()) == "description(values)"

x = rand(4,4)
@test @inferred(calmin(x)) == minimum(x)
@test @inferred(calmax(x)) == maximum(x)

T = FieldProperties.calmin_type(x)
@test T <: Float64
T = FieldProperties.calmax_type(x)
@test T <: Float64

# TODO delete 
@test proptype(calmin, x) <: Float64
@test proptype(calmax, x) <: Float64

include("metadata_tests.jl")

@testset "FieldProperties docs" begin
    doctest(FieldProperties; manual=false)
end

@test_throws ErrorException("Argument referring to value is inconsistent, got x and y.") FieldProperties.check_args(:x, :y)

@test_throws ErrorException("Argument referring to self is inconsistent, got w and z.") FieldProperties.check_args(:w, :z, :x, :y)

#=
doc = Docs.DocStr(Core.svec(), nothing, Dict())
buf = IOBuffer()

d = @doc(ExampleStruct).meta[:results][1]
DocStringExtensions.format(GETPROPERTY, buf, 
=#
