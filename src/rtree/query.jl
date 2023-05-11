export VisitorState, traverse, traverse_parent, traverse_child, increment_last!, should_visit

abstract type ChildOrdering end
struct NoOrdering <: ChildOrdering end

ordering(children, ::NoOrdering) = children

# Visitor pattern
Base.@kwdef mutable struct VisitorState{Q<:AbstractQuery, O<:ChildOrdering}
    index_stack::Vector{Int} = Vector{Int}()
    current_node::Union{AbstractNode, Nothing} = nothing 
    query::Q = AllQuery()
    ordering::O = NoOrdering()
    return_leaf::Bool = false
end

function traverse(node::Branch, state)
    increment_last!(state.index_stack)
    n = length(node)

    children = ordering(node.children, state.ordering)

    while last(state.index_stack) <= n
        child = children[last(state.index_stack)]
        if should_visit(child, state)
            return traverse_child(child, state)
        end
        increment_last!(state.index_stack)
    end

    return traverse_parent(node, state)
end

function traverse(node::Leaf, state)
    if state.return_leaf
        return node
    end

    increment_last!(state.index_stack)
    n = length(node)

    while last(state.index_stack) <= n
        elem = node.data[last(state.index_stack)]
        if satisfy(state.query, elem)
            return elem, state
        end
        increment_last!(state.index_stack)
    end

    return traverse_parent(node, state)
end

function traverse_child(child, state)
    push!(state.index_stack, 0)
    state.current_node = child
    return traverse(child, state)
end

function traverse_parent(node, state)
    if isroot(node)
        return nothing
    end

    pop!(state.index_stack)
    state.current_node = node.parent
    return traverse(node.parent, state)
end

# Exploit tree structure to prune visiting
function should_visit(node::AbstractNode, state::VisitorState{Q}) where {T, Q<:AbstractSpatialQuery{T}}
    if has_mbr(state.query)
        return !is_mbr_disjoint(state.query, node)
    else
        return !isdisjoint(region(state.query), mbr(node))
    end
end
should_visit(node::AbstractNode, state::VisitorState{Q}) where {Q<:AbstractQuery} = true

function increment_last!(stack)
    stack[end] += 1
end

# Access methods
# WARNING: Do not interleave update and iterate
function Base.iterate(index::RTreeIndex)
    if isempty(index)
        return nothing
    end

    return traverse_child(index.root, VisitorState())
end
Base.iterate(::RTreeIndex, state) = traverse(state.current_node, state)

function findfirst(query, index::RTreeIndex)
    if isempty(index)
        return nothing
    end

    state = VisitorState(query=query)
    it = traverse_child(index.root, state)

    if isnothing(it)
        return nothing
    end

    return it[1]
end

function findall(query, index::RTreeIndex)
    match = []

    if isempty(index)
        return match
    end

    state = VisitorState(query=query)
    it = traverse_child(index.root, state)

    while !isnothing(it)
        elem, state = it
        push!(match, elem)

        it = traverse(state.current_node, state)
    end

    return match
end