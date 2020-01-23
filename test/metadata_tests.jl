
@testset "Metadata" begin
    m = Metadata(; a = 1, b= 2)
    @test m.a == 1
    @test m.b == 2
    m.b = 3
    @test m.b == 3
end

@testset "NoopMetadata" begin
    np = NoopMetadata()

    @test @inferred(isempty(np))
    @test @inferred(isnothing(get(np, :anything, nothing)))
    @test @inferred(length(np)) == 0
    @test @inferred(haskey(np, :anything)) == false
    @test @inferred(in(:anything, np)) == false
    @test @inferred(propertynames(np)) == ()
    @test @inferred(isnothing(iterate(np)))
    @test @inferred(isnothing(iterate(np, 1)))

    @test_throws MethodError setindex!(np, :bar, 1)
end
