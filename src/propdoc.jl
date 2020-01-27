"""
    propdoc(x) -> String

Returns documentation for property `x`.
"""
propdoc(::T) where {T} = propdoc(T)
propdoc(::Type{P}) where {P<:AbstractProperty} = _extract_doc(Base.Docs.doc(P))
function propdoc(::Type{T}) where {T}
    pnames = assigned_fields(T)
    return NamedTuple{pnames}(([propdoc(sym2prop(T, p)) for p in pnames]...,))
end

_extract_doc(x::Markdown.MD) = _extract_doc(x.content)
_extract_doc(x::AbstractArray) = isempty(x) ? "" : _extract_doc(first(x))
_extract_doc(x::Markdown.Paragraph) = _extract_doc(x.content)
_extract_doc(x::String) = x

"""
    propdoclist(::T) -> String

Returns a markdown list of properties, where `T` is a type that has been assigned
properties (see [`@assignprops`](@ref)) 
"""
function propdoclist(x)
    out = ""
    for (p, d) in pairs(propdoc(x))
        out = out * "* $p: $d\n"
    end
    return out
end

