struct InsertionOrdering <: ChildOrdering
    elem
    mbr
end
InsertionOrdering(elem) = InsertionOrdering(elem, mbr(elem))

function ordering(children, ordering::InsertionOrdering)
    primary_goal = Base.findall(child -> ordering.mbr ⊆ mbr(child), children)

    if !isempty(primary_goal)
        children = children[primary_goal]
        sort!(children, by=(node -> volume(mbr(node))))

        return children
    end
    
    enlargement(node) = volume(join_mbr(ordering.mbr, mbr(node))) - volume(mbr(node))
    sort!(children, by=enlargement)
    return children
end

function Base.insert!(index::RTreeIndex, elem)
    @assert has_mbr(elem), "All elements in an R-tree must have an MBR."

    node = find_destination_node(index, elem)
    insert!(node, elem)

    while should_split(node, index.update_strategy)

    end

    update_ancestor_mbrs!(node)
end

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

should_split(node::Leaf, update_strategy::OrdinaryRTreeUpdateStrategy) = length(node) >= update_strategy.leaf_capacity
should_split(node::Branch, update_strategy::OrdinaryRTreeUpdateStrategy) = length(node) >= update_strategy.branch_capacity

function update_ancestor_mbrs!(node)
    if !isroot(node)
        parent = node.parent
        parent.mbr = join_mbr(parent.mbr, node.mbr)
    end
end