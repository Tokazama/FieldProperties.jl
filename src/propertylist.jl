
"""
    AbstractPropertyList{M <: AbstractDict{Symbol,Any}} <: AbstractDict{Symbol,Any}

Abstract type for storing metadata.
"""
abstract type AbstractPropertyList{D<:AbstractDict{Symbol,Any}} <: AbstractDict{Symbol,Any} end

Base.empty!(m::AbstractPropertyList) = empty!(dictextension(m))

Base.get(m::AbstractPropertyList, k, default) = get(dictextension(m), k, default)

Base.get!(m::AbstractPropertyList, k, default) = get!(dictextension(m), k, default)

# TODO
#Base.in(k, m::AbstractPropertyList) = in(k, propname(m))

#Base.pop!(m::AbstractPropertyList, k) = pop!(dictextension(m), k)

#Base.pop!(m::AbstractPropertyList, k, default) = pop!(dictextension(m), k, default)

Base.isempty(m::AbstractPropertyList) = isempty(dictextension(m))

Base.delete!(m::AbstractPropertyList, k) = delete!(dictextension(m), k)

@inline Base.getindex(x::AbstractPropertyList, s::Symbol) = getindex(dictextension(x), s)

@inline function Base.setindex!(x::AbstractPropertyList, val, s::Symbol)
    return setindex!(dictextension(x), val, s)
end

Base.length(m::AbstractPropertyList) = length(dictextension(m))

Base.getkey(m::AbstractPropertyList, k, default) = getkey(dictextension(m), k, default)

Base.keys(m::AbstractPropertyList) = keys(dictextension(m))

Base.propertynames(m::AbstractPropertyList) = Tuple(keys(m))

suppress(m::AbstractPropertyList) = get(m, :suppress, ())

Base.show(io::IO, m::AbstractPropertyList) = showdictlines(io, m, suppress(m))
Base.show(io::IO, ::MIME"text/plain", m::AbstractPropertyList) = showdictlines(io, m, suppress(m))
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

Base.iterate(m::AbstractPropertyList) = iterate(dictextension(m))

Base.iterate(m::AbstractPropertyList, state) = iterate(dictextension(m), state)

"""
    NoopPropertyList

Empty dictionary that indicates there is no metadata.
"""
struct NoopPropertyList <: AbstractPropertyList{Dict{Symbol,Any}} end

Base.isempty(::NoopPropertyList) = true

Base.get(::NoopPropertyList, k, default) = default

Base.length(::NoopPropertyList) = 0

Base.haskey(::NoopPropertyList, k) = false

Base.in(k, ::NoopPropertyList) = false

Base.propertynames(::NoopPropertyList) = ()

Base.iterate(m::NoopPropertyList) = nothing

Base.iterate(m::NoopPropertyList, state) = nothing

function Base.setindex!(m::NoopPropertyList, val, s::Symbol)
    error("Cannot set property for NoopPropertyList.")
end

"""
    PropertyList{D}

Subtype of `AbstractPropertyList` that provides `getproperty` syntax for accessing
the values of a dictionary.

## Examples
```jldoctest
julia> using FieldProperties

julia> m = PropertyList(; a = 1, b= 2)
PropertyList{Dict{Symbol,Any}} with 2 entries
    a: 1
    b: 2

julia> getindex(m, :a)
1

julia> get(m, :a, 3)
1

julia> get!(m, :a, 3)
1

julia> m.a
1

julia> m[:a] = 2
2

julia> m.a
2

julia> m.b
2

julia> m.b = 3
3

julia> m.b
3

julia> m.name = "ridiculously long name that we don't want to print everytime the other properties are printed.";


julia> m.suppress = (:name,)
(:name,)

julia> m
PropertyList{Dict{Symbol,Any}} with 4 entries
    a: 2
    b: 3
    name: <suppressed>
    suppress: (:name,)
```
"""
struct PropertyList{D} <: AbstractPropertyList{D}
    dictextension::D
end

function PropertyList(; kwargs...)
    out = PropertyList(Dict{Symbol,Any}())
    for (k,v) in kwargs
        setproperty!(out, k, v)
    end
    return out
end

dictextension(m::PropertyList) = getfield(m, :dictextension)

Base.getproperty(m::PropertyList, s::Symbol) = getindex(dictextension(m), s)

Base.setproperty!(m::PropertyList, s::Symbol, val) = setindex!(dictextension(m), val, s)

const PropertyArray{T,N,P<:AbstractPropertyList,A} = MetadataArray{T,N,P,A}

function PropertyArray(A::AbstractArray, properties::AbstractPropertyList=NoopPropertyList())
    return PropertyArray(A, properties)
end

