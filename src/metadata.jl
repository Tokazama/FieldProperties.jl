"""
    AbstractMetadata{M <: AbstractDict{Symbol,Any}} <: AbstractDict{Symbol,Any}

Abstract type for storing metadata.
"""
abstract type AbstractMetadata{D<:AbstractDict{Symbol,Any}} <: AbstractDict{Symbol,Any} end

Base.empty!(m::AbstractMetadata) = empty!(dictextension(m))

Base.get(m::AbstractMetadata, k, default) = get(dictextension(m), k, default)

Base.get!(m::AbstractMetadata, k, default) = get!(dictextension(m), k, default)

# TODO
#Base.in(k, m::AbstractMetadata) = in(k, propname(m))

#Base.pop!(m::AbstractMetadata, k) = pop!(dictextension(m), k)

#Base.pop!(m::AbstractMetadata, k, default) = pop!(dictextension(m), k, default)

Base.isempty(m::AbstractMetadata) = isempty(dictextension(m))

Base.delete!(m::AbstractMetadata, k) = delete!(dictextension(m), k)

@inline Base.getindex(x::AbstractMetadata, s::Symbol) = getindex(dictextension(x), s)

@inline function Base.setindex!(x::AbstractMetadata, val, s::Symbol)
    return setindex!(dictextension(x), val, s)
end

Base.length(m::AbstractMetadata) = length(dictextension(m))

Base.getkey(m::AbstractMetadata, k, default) = getkey(dictextension(m), k, default)

Base.keys(m::AbstractMetadata) = keys(dictextension(m))

Base.propertynames(m::AbstractMetadata) = Tuple(keys(m))

suppress(m::AbstractMetadata) = get(m, :suppress, ())

Base.show(io::IO, m::AbstractMetadata) = showdictlines(io, m, suppress(m))
Base.show(io::IO, ::MIME"text/plain", m::AbstractMetadata) = showdictlines(io, m, suppress(m))
function showdictlines(io::IO, m, suppress)
    print(io, summary(m))
    for (k, v) in m
        if !in(k, suppress)
            print(io, "\n    ", k, ": ")
            print(IOContext(io, :compact => true), v)
        else
            print(io, "\n    ", k, ": <suppressed>")
        end
    end
end

Base.iterate(m::AbstractMetadata) = iterate(dictextension(m))

Base.iterate(m::AbstractMetadata, state) = iterate(dictextension(m), state)

"""
    NoopMetadata

Empty dictionary that indicates there is no metadata.
"""
struct NoopMetadata <: AbstractMetadata{Dict{Symbol,Any}} end

Base.isempty(::NoopMetadata) = true

Base.get(::NoopMetadata, k, default) = default

Base.length(::NoopMetadata) = 0

Base.haskey(::NoopMetadata, k) = false

Base.in(k, ::NoopMetadata) = false

Base.propertynames(::NoopMetadata) = ()

Base.iterate(m::NoopMetadata) = nothing

Base.iterate(m::NoopMetadata, state) = nothing

function Base.setindex!(m::NoopMetadata, val, s::Symbol)
    error("Cannot set property for NoopMetadata.")
end

"""
    Metadata{D}

Subtype of `AbstractMetadata` that provides `getproperty` syntax for accessing
the values of a dictionary.
"""
struct Metadata{D} <: AbstractMetadata{D}
    dictextension::D
end

function Metadata(; kwargs...)
    out = Metadata(Dict{Symbol,Any}())
    for (k,v) in kwargs
        setproperty!(out, k, v)
    end
    return out
end

dictextension(m::Metadata) = getfield(m, :dictextension)

Base.getproperty(m::Metadata, s::Symbol) = getindex(dictextension(m), s)

Base.setproperty!(m::Metadata, s::Symbol, val) = setindex!(dictextension(m), val, s)
#=

## Examples

```jldoctest
julia> using FieldProperties

julia> m = Metadata(; a = 1, b= 2)
Metadata{Dict{Symbol,Any}} with 2 entries
    a: 1
    b: 2

julia> propertynames(m)
(:a, :b)

julia> m[:a]
1

julia> m.a
1

julia> get(m, :a, 3) == get!(m, :a, 3) == 1
true

julia> get!(m, :c, 3)
3

julia> m.c
3

julia> m.d = 3
3

julia> m.d
3

julia> isempty(m)
false

julia> empty!(m)
Dict{Symbol,Any} with 0 entries

julia> isempty(m)
true

```

=#
