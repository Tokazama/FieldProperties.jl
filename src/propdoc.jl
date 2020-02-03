"""
    propdoc(x) -> String

Returns documentation for property `x`.
"""
propdoc(::T) where {T} = propdoc(T)
propdoc(::Type{P}) where {P<:AbstractProperty} = _extract_doc(Base.Docs.doc(P))

_extract_doc(x::Markdown.MD) = _extract_doc(x.content)
_extract_doc(x::AbstractArray) = isempty(x) ? "" : _extract_doc(first(x))
_extract_doc(x::Markdown.Paragraph) = _extract_doc(x.content)
_extract_doc(x::String) = x

"""
    propdoclist(ps...) -> String

Returns a markdown list of properties given multiple properties `ps`.
"""
function propdoclist(ps...)
    out = ""
    for p_i in ps
        out = out * "* $(propname(p_i)): $(propdoc(p_i))\n"
    end
    return out
end


