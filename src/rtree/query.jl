export VisitorState, traverse, should_visit

# Visitor pattern
mutable struct VisitorState{Q<:AbstractQuery}
    level_indices::Vector{Int}
    current_node::AbstractNode
    query::Q
end

function traverse(node::Branch, state)

end

function traverse(node::Leaf, state)
    
end

# Exploit tree structure to prune visiting
function should_visit(node::AbstractNode, state::VisitorState{Q}) where {T, Q<:AbstractSpatialQuery{T}}
    return !is_mbr_disjoint(state.query, node)
end
should_visit(node::AbstractNode, state::VisitorState{Q}) where {Q<:AbstractQuery} = true

# Access methods
function Base.iterate(index::RTree{T, E})
    if isempty(index)
        return nothing
    end


end
