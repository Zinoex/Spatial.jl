
function Base.insert!(index::LinearIndex, elem)
    push!(index.container, elem)
end

function Base.delete!(query, index::LinearIndex)
    deleteat!(index.container, Base.findall(elem -> satisfy(query, elem), index.container))
end