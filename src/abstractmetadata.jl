
"""
    AbstractMetadata
"""
abstract type AbstractMetadata{D<:AbstractDict{Symbol,Any}} <: AbstractDict{Symbol,Any} end

Base.empty!(m::AbstractMetadata) = empty!(properties(m))

Base.get(m::AbstractMetadata, k, default) = get(properties(m), k, default)

Base.get!(m::AbstractMetadata, k, default) = get!(properties(m), k, default)

# TODO
#Base.in(k, m::AbstractMetadata) = in(k, propname(m))

#Base.pop!(m::AbstractMetadata, k) = pop!(properties(m), k)

#Base.pop!(m::AbstractMetadata, k, default) = pop!(properties(m), k, default)

Base.isempty(m::AbstractMetadata) = isempty(properties(m))

Base.delete!(m::AbstractMetadata, k) = delete!(properties(m), k)

@inline Base.getindex(x::AbstractMetadata, s::Symbol) = getindex(properties(x), s)

@inline function Base.setindex!(x::AbstractMetadata, val, s::Symbol)
    return setindex!(properties(x), val, s)
end

function ImageMetadata.properties(m::AbstractMetadata)
    error("All subtypes of AbstractMetadata must implement a properties method.")
end

"""
    struct_properties(::Type{M}) = Tuple{Vararg{Symbol}}
"""
struct_properties(::M) where {M} = struct_properties(M)
struct_properties(::Type{M}) where {M} = ()

# propertynames
@inline function Base.propertynames(m::AbstractMetadata{D}) where {D<:AbstractMetadata}
    return (struct_properties(m)..., propertynames(properties(m))...)
end

@inline function Base.propertynames(m::AbstractMetadata{D}) where {D}
    return (struct_properties(m)..., keys(properties(m))...)
end

Base.length(m::AbstractMetadata) = length(propertynames(m))

Base.getkey(m::AbstractMetadata, k, default) = getkey(properties(m), k, default)

Base.keys(m::AbstractMetadata) = propertynames(m)

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

function Base.iterate(m::AbstractMetadata, state=1)
    out = iterate_struct(m, state)
    if isnothing(out)
        np = length(struct_properties(m))
        out = iterate(properties(m), state - np)
        if isnothing(out)
            return nothing
        else
            k, i = out
            return k, i + np
        end
    else
        return out
    end
end

@inline function iterate_struct(m::AbstractMetadata, state = 1)
    propnames = struct_properties(m)
    if state > length(propnames)
        return nothing
    else
        p = @inbounds(propnames[state])
        return Pair(p, getfield(m, p)), state + 1
    end
end

function get_property(m::AbstractMetadata{M}, s::Symbol) where {M<: AbstractMetadata}
    for p in struct_properties(m)
        if p === s
            return getfield(m, s)
        end
    end
    return get_property(properties(m), s)
end

function get_property(m::AbstractMetadata{M}, s::Symbol) where {M}
    for p in struct_properties(m)
        if p === s
            return getfield(m, s)
        end
    end
    return getindex(properties(m), s)
end

function set_property!(m::AbstractMetadata{M}, s::Symbol, val) where {M<: AbstractMetadata}
    for p in struct_properties(m)
        if p === s
            return setfield!(m, s, val)
        end
    end
    return set_property!(properties(m), s, val)
end

function set_property!(m::AbstractMetadata{M}, s::Symbol, val) where {M}
    for p in struct_properties(m)
        if p === s
            return setfield!(m, s, val)
        end
    end
    return setindex!(properties(m), val, s)
end
