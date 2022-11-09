export AbstractNode, Branch, Leaf, RTreeIndex
export level, tree_height, isroot, next_id!
export RTreeUpdateStrategy, OrdinaryRTreeUpdateStrategy

abstract type AbstractNode{T, E} end
has_mbr(node::AbstractNode) = true
mbr(node::AbstractNode) = node.mbr
isroot(node::AbstractNode) = isnothing(node.parent)
Base.:(==)(x::AbstractNode, y::AbstractNode) = x.id == y.id

mutable struct Branch{T, E, C<:AbstractNode{T, E}} <: AbstractNode{T, E} 
    id::Int
    # Parent must be a branch whose child nodes are of type Branch{T, E, C}, aka. this.
    parent::Union{Branch{T, E, Branch{T, E, C}}, Nothing}
    level::Int

    mbr::AbstractHyperrectangle{T}
    children::AbstractVector{C}  # Either you have more branches or you only have leaves as children
end
Branch(id, level, mbr, children) = Branch(id, nothing, level, mbr, children)

level(node::Branch) = node.level
Base.length(node::Branch) = length(node.children)


mutable struct Leaf{T, E} <: AbstractNode{T, E} 
    id::Int
    # Parent must be a branch whose child nodes are of type Leaf{T, E}, aka. this.
    parent::Union{Branch{T, E, Leaf{T, E}}, Nothing}

    mbr::Union{AbstractHyperrectangle{T}, Nothing}
    data::AbstractVector{E}  # Vector of data elements
end
Leaf{T, E}(id) where {T, E} = Leaf{T, E}(id, nothing, nothing, Vector{E}())
Leaf(id, mbr, data) = Leaf(id, nothing, mbr, data)

level(node::Leaf) = 1
Base.length(node::Leaf) = length(node.data)


abstract type RTreeUpdateStrategy end

Base.@kwdef struct OrdinaryRTreeUpdateStrategy <: RTreeUpdateStrategy
    branch_capacity = 100
    leaf_capacity = 100

    min_fill = 0.4   # percentage
end

mutable struct RTreeIndex{T, D, E} <: AbstractSpatialIndex{T, E}
    nelem::Int
    root::AbstractNode{T, E}
    next_id::Int   # DO NOT ACCESS DIRECTLY - use next_id!(index)

    update_strategy::RTreeUpdateStrategy
end
RTreeIndex{T, D, E}() where {T, D, E} = RTreeIndex{T, D, E}(OrdinaryRTreeUpdateStrategy())
RTreeIndex{T, D, E}(update_strategy) where {T, D, E} = RTreeIndex{T, D, E}(0, Leaf{T, E}(1), 1, update_strategy)

Base.isempty(index::RTreeIndex) = length(index) == 0
Base.length(index::RTreeIndex) = index.nelem
Base.eltype(::RTreeIndex{T, D, E}) where {T, D, E} = E
tree_height(index::RTreeIndex) = level(index.root)
function next_id!(index)
    index.next_id += 1
    return index.next_id
end