
"""
    name(x) -> Symbol
    name!(x, val)

Property providing name for parent structure.
"""
@defprop Name{:name}::Symbol

"""
    name(x::AbstractProperty) -> Symbol

Returns the symbolic name of the property.
"""
name(::P) where {P<:AbstractProperty} = name(P)
name(::Type{<:AbstractProperty{n}}) where {n} = n


"""
    description(x) -> String

Description that may say whatever you like.

---

    description(x::AbstractProperty) -> String

Returns description for property `x`.
## Examples
```jldoctest
julia> using FieldProperties

julia> description(description)
"Description that may say whatever you like.\\n"
```
"""
@defprop Description{:description}::String

description(x::T) where {T<:AbstractProperty} = _extract_doc(Base.Docs.doc(T))
function _extract_description(x::AbstractArray)
    for x_i in x
        out = _extract_description(x_i)
        out isa AbstractString && return out
    end
end
_extract_description(x::Markdown.Code) = nothing
function _extract_description(x::Markdown.Paragraph)
    io = IOBuffer()
    Markdown.plain(io, x)
    str = String(take!(io))
    return str
end

function _extract_doc(x::Markdown.MD)
    if first(x.content) isa Markdown.MD
        return _extract_doc(first(x.content))
    else
        return _extract_description(x.content)
    end
end

"""
    description_list(ps...) -> String

Returns a markdown list where eache element of `ps` is formatted as:

```
* name(ps[i]): description(ps[i]).
```

## Examples
```jldoctest
julia> using FieldProperties

julia> description_list(description, calmax)
"* `description`: Description that may say whatever you like.\\n* `calmax`: Specifies maximum element for display purposes. If not specified returns the maximum value in the collection.\\n"
```
"""
function description_list(ps...)
    out = ""
    for p_i in ps
        out = out * "* `$(name(p_i))`: $(description(p_i))"
    end
    return out
end

struct TypeGetProperty <: DocStringExtensions.Abbreviation end

const GETPROPERTY = TypeGetProperty()

function DocStringExtensions.format(abbrv::TypeGetProperty, buf, doc)
    local docs = get(doc.data, :getproperty, Dict())
    local binding = doc.data[:binding]
    local object = Docs.resolve(binding)
    if !isempty(docs)
        println(buf)
        for (k,v) in docs
            if v != nothing
                println(buf, "  - ` $k `: $v")
            end
            println(buf)
        end
        println(buf)
    end
    return nothing
end

struct TypeSetProperty <: DocStringExtensions.Abbreviation end

const SETPROPERTY = TypeSetProperty()

function DocStringExtensions.format(abbrv::TypeSetProperty, buf, doc)
    local docs = get(doc.data, :setproperty!, Dict())
    if !isempty(docs)
        println(buf)
        for (k,v) in docs
            if v != nothing
                println(buf, "  - `", k, "`: ", v)
            end
            println(buf)
        end
        println(buf)
    end
    return nothing
end

