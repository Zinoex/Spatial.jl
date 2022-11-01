

function Base.delete!(query, index::RTreeIndex)
end

function Base.deleteat!(node::Branch, i::Int)
    deleteat!(node.children, i)
end