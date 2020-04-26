using FieldProperties, Test, Documenter

@testset "Print multiple methods" begin
    io = IOBuffer()
    show(io, description)
    str = String(take!(io))
    @test str == "description (generic function with 3 methods)"

    io = IOBuffer()
    show(io, MIME"text/plain"(), description!)
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

"""
    TestStruct

"""
struct TestStruct
    "x"
    p1
    p2
    p3
    p4
    p5
end

@properties TestStruct begin
    "prop1 str"
    prop1(self) => :p1
    prop2(self) => :p2
    prop3(self) => :p3
    "setter str"
    prop4!(self, val) => :p4
    Any(self) => :p5
    Any!(self, val) => :p5
end

t = TestStruct(1,2,3,4,5)


@test propertynames(t) == (:prop1,:prop2,:prop3,:prop4)


d = @doc(TestStruct).meta[:results][1]
io = IOBuffer()
FieldProperties.DocStringExtensions.format(SETPROPERTY, io, d)
@test occursin("- `prop4`: setter str", String(take!(io)))

io = IOBuffer()
FieldProperties.DocStringExtensions.format(GETPROPERTY, io, d)
@test occursin("- ` prop1 `: prop1 str", String(take!(io)))


# does it error without nested documentation
@properties TestStruct begin
    prop1(self) => :p1
    prop2(self) => :p2
    prop3(self) => :p3
    prop4!(self, val) => :p4
end
@test propertynames(t) == (:prop1,:prop2,:prop3,:prop4)

FieldProperties._fxnname(FieldProperties.Description{values}()) == "description(values)"

x = rand(4,4)
@test @inferred(calmin(x)) == minimum(x)
@test @inferred(calmax(x)) == maximum(x)

T = FieldProperties.calmin_type(x)
@test T <: Float64
T = FieldProperties.calmax_type(x)
@test T <: Float64

include("metadata_tests.jl")

@testset "FieldProperties docs" begin
    doctest(FieldProperties)
end

@test_throws ErrorException("Argument referring to value is inconsistent, got x and y.") FieldProperties.check_args(:x, :y)

@test_throws ErrorException("Argument referring to self is inconsistent, got w and z.") FieldProperties.check_args(:w, :z, :x, :y)


