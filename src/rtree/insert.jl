export InsertionOrdering, optimal_insert_index, find_destination_node
export recursive_split!, should_split, split!, distribute
export update_ancestor_mbrs!

function Base.insert!(index::RTreeIndex, elem)
    @assert has_mbr(elem) "All elements in an R-tree must have an MBR."

    node = find_destination_node(index, elem)
    insert!(node, elem)

    node = recursive_split!(index, node, elem, index.update_strategy)

    update_ancestor_mbrs!(node)

    index.nelem += 1
end

struct InsertionOrdering <: ChildOrdering
    elem
    mbr
end
InsertionOrdering(elem) = InsertionOrdering(elem, mbr(elem))

function optimal_insert_index(children, ordering::InsertionOrdering)
    primary_goal = Base.findall(child -> ordering.mbr ⊆ mbr(child), children)

    if !isempty(primary_goal)
        return argmin(idx -> volume(mbr(children[idx])), primary_goal)
    end
    
    enlargement(idx) = volume(join_mbr(ordering.mbr, mbr(children[idx]))) - volume(mbr(children[idx]))

    return argmin(enlargement, eachindex(children))
end

ordering(children, ordering::InsertionOrdering) = [children[optimal_insert_index(children, ordering)]]

function find_destination_node(index::RTreeIndex, elem)
    state = VisitorState(ordering=InsertionOrdering(elem), return_leaf=true)
    return traverse_child(index.root, state)
end

function Base.insert!(node::Leaf, elem)
    push!(node.data, elem)
    if isnothing(node.mbr)
        node.mbr = mbr(elem)
    else
        node.mbr = join_mbr(node.mbr, mbr(elem))
    end
end

function Base.insert!(parent::Branch, child::AbstractNode)
    push!(parent.children, child)
end

function recursive_split!(index::RTreeIndex, node::AbstractNode, elem, update_strategy)
    if !should_split(node, update_strategy)
        return node
    end

    node1, node2 = split(node, update_strategy)

    if isroot(node)
        node = Branch(nothing, level(node) + 1, join_mbr(mbr(node1), mbr(node2)), [node1, node2])
        index.root = node
        node1.parent = node
        node2.parent = node

        return node
    end

    idx = optimal_insert_index(node.parent.children, InsertionOrdering(elem))
    deleteat!(node.parent, idx)

    insert!(node.parent, node1)
    insert!(node.parent, node2)
    node.parent.mbr = join_mbr(mbr(node.parent), mbr(node1), mbr(node2))

    return recursive_split!(index, node, elem, update_strategy)
end

should_split(node::Leaf, update_strategy::OrdinaryRTreeUpdateStrategy) = length(node) > update_strategy.leaf_capacity
should_split(node::Branch, update_strategy::OrdinaryRTreeUpdateStrategy) = length(node) > update_strategy.branch_capacity

function split(node::Leaf, update_strategy)
    N₁, N₂ = distribute(node.data, update_strategy, update_strategy.leaf_capacity)
    node1 = Leaf(node.parent, join_mbr(mbr.(N₁)), N₁)
    node2 = Leaf(node.parent, join_mbr(mbr.(N₂)), N₂)
    
    return node1, node2
end

function split(node::Branch, update_strategy)
    N₁, N₂ = distribute(node.children, update_strategy, update_strategy.branch_capacity)

    node1 = Branch(node.parent, level(node), join_mbr(mbr.(N₁)), N₁)
    node2 = Branch(node.parent, level(node), join_mbr(mbr.(N₂)), N₂)

    for i in eachindex(N₁)
        node1.children[i].parent = node1
    end

    for i in eachindex(N₂)
        node2.children[i].parent = node2
    end

    return node1, node2
end

function distribute(elems, update_strategy::OrdinaryRTreeUpdateStrategy, capacity)
    # https://www.just.edu.jo/~qmyaseen/rtree1.pdf - Fig. 3 (Alg. NDistribute)
    i₁ = argmin(idx -> (sum ∘ low ∘ mbr)(elems[idx]), eachindex(elems))
    s₁ = elems[i₁]
    deleteat!(elems, i₁)

    i₂ = argmax(idx -> (sum ∘ high ∘ mbr)(elems[idx]), eachindex(elems))
    s₂ = elems[i₂]
    deleteat!(elems, i₂)

    dist_s₁(elem) = norm(low(mbr(s₁)) .- high(mbr(elem)))
    dist_s₂(elem) = norm(low(mbr(elem)) .- high(mbr(s₂)))

    min_fill = floor(Int, capacity * update_strategy.min_fill)

    sort!(elems, by=dist_s₁)
    N₁ = elems[1:min_fill]
    elems = elems[min_fill + 1:end]

    sort!(elems, by=dist_s₂)
    N₂ = elems[1:min_fill]
    elems = elems[min_fill + 1:end]

    for elem in elems
        if dist_s₁(elem) < dist_s₂(elem)
            push!(N₁, elem)
        else
            push!(N₂, elem)
        end
    end

    push!(N₁, s₁)
    push!(N₂, s₂)

    return N₁, N₂
end

function update_ancestor_mbrs!(node)
    if !isroot(node)
        parent = node.parent
        parent.mbr = join_mbr(parent.mbr, node.mbr)

        update_ancestor_mbrs!(parent)
    end
end