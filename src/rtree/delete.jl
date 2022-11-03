

function Base.delete!(query, index::RTreeIndex)
end

function Base.deleteat!(node::Branch, i::Int)
    deleteat!(node.children, i)
end

function Base.delete!(node::Branch, query::AbstractNode)
    idx = Base.findfirst(child -> child == query, node.children)
    if isnothing(idx)
        throw(KeyError("Child not found in branch"))
    end
    deleteat!(node, idx)
end