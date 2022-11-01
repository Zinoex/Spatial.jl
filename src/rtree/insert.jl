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

        return node
    end

    idx = optimal_insert_index(node.parent.children, InsertionOrdering(elem))
    deleteat!(node.parent, idx)

    insert!(node.parent, node1)
    insert!(node.parent, node2)
    node.parent.mbr = join_mbr(node.parent.mbr, node1, node2)

    return recursive_split!(index, node, elem, update_strategy)
end

should_split(node::Leaf, update_strategy::OrdinaryRTreeUpdateStrategy) = length(node) >= update_strategy.leaf_capacity
should_split(node::Branch, update_strategy::OrdinaryRTreeUpdateStrategy) = length(node) >= update_strategy.branch_capacity

function update_ancestor_mbrs!(node)
    if !isroot(node)
        parent = node.parent
        parent.mbr = join_mbr(parent.mbr, node.mbr)

        update_ancestor_mbrs!(parent)
    end
end