export top_down_greedy

function bulk_load!(index::RTreeIndex{T, E}, data::VE) where {T, E, VE<:AbstractVector{E}}
    @assert isempty(index) "Cannot bulk load if index is not empty"

    update_strategy = index.update_strategy
    N = length(data)
    N_leaves = ceil(Int, N / update_strategy.leaf_capacity)
    
    internal_height = ceil(Int, log(update_strategy.branch_capacity, N_leaves))
    
    root = top_down_greedy(index, internal_height + 1, data)
    index.root = root
    index.nelem = N
    
    return index
end

function top_down_greedy(index::RTreeIndex{T, E}, level, data)  where {T, E}
    N = length(data)

    # If number of objects is less than or equal than max children per leaf,
	# we need to create a leaf node, although possibly with branches inbetween.
	if N <= index.update_strategy.leaf_capacity
		if level > 1
			child = top_down_greedy(index, level - 1, data)
            node = Branch(next_id!(index), nothing, level, mbr(child), [child])
			child.parent = node
			return node
        end

		node = Leaf(next_id!(index), nothing, join_mbr(mbr.(data)), data)
        return node
	end

    # If not a leaf, we need to sort the data and split into {index.update_strategy.branch_capacity} partitions
    D = LazySets.dim(mbr(first(data)))
    N_per_node = ceil(Int, N / index.update_strategy.branch_capacity)
    sort!(data, by=elem -> center(mbr(elem))[(level % D) + 1])

    children = [top_down_greedy(index, level - 1, subset) for subset in partition(data, N_per_node)]
    node = Branch(next_id!(index), nothing, level, join_mbr(mbr.(children)), children)
    
    for i in eachindex(children)
        node.children[i].parent = node
    end

	return node
end

struct PartitionIterator
    data
    split_size
end
partition(data, split_size) = PartitionIterator(data, split_size)

Base.iterate(iter::PartitionIterator) = isempty(iter.data) ? nothing : (iter.data[1:iter.split_size], 1)
function Base.iterate(iter::PartitionIterator, i)
    if i < length(iter)
        start_idx = i * iter.split_size + 1
        end_idx = (i + 1) * iter.split_size

        if end_idx > length(iter.data)
            return iter.data[start_idx:end], i + 1
        end

        return iter.data[start_idx:end_idx], i + 1
    end

    return nothing
end
Base.eltype(iter::PartitionIterator) = AbstractVector{eltype(iter.data)}
Base.length(iter::PartitionIterator) = ceil(Int, length(iter.data) / iter.split_size)