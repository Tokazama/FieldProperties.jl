using FieldProperties, Test, Documenter

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

struct ArrayLike{T,N}
    a::Array{T,N}
    calmax::T
    calmin::T
end

xdiff = -(extrema(x)...)
xmax = maximum(x) - .25 * xdiff
xmin = minimum(x) + .25 * xdiff
a = ArrayLike(x, xmax, xmin)
@test calmax(a) == xmax
@test calmin(a) == xmin

@testset "property documentation" begin
    @test propdoclist(description, calmax) == "* description: Description that may say whatever you like.\n* calmax: Specifies maximum element for display purposes. If not specified returns the maximum value in the collection.\n"
end

include("metadata_tests.jl")

@testset "FieldProperties docs" begin
    doctest(FieldProperties; manual=false)
end

@test_throws ErrorException("Argument referring to value is inconsistent, got x and y.") FieldProperties.check_args(:x, :y)

@test_throws ErrorException("Argument referring to self is inconsistent, got w and z.") FieldProperties.check_args(:w, :z, :x, :y)

