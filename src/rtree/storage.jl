export AbstractNode, Branch, Leaf, RTreeIndex
export level, tree_height, isroot, next_id!
export RTreeUpdateStrategy, OrdinaryRTreeUpdateStrategy

abstract type AbstractNode{T, E} end
has_mbr(node::AbstractNode) = true
mbr(node::AbstractNode) = node.mbr
isroot(node::AbstractNode) = isnothing(node.parent)
Base.:(==)(x::AbstractNode, y::AbstractNode) = x.id == y.id

mutable struct Branch{T, E} <: AbstractNode{T, E} 
    id::Int

    parent::Union{Branch{T, E}, Nothing}
    level::Int

    mbr::AbstractHyperrectangle{T}
    children::AbstractVector{<:AbstractNode{T, E}}
end
Branch(id, level, mbr, children) = Branch(id, nothing, level, mbr, children)

level(node::Branch) = node.level
Base.length(node::Branch) = length(node.children)


mutable struct Leaf{T, E} <: AbstractNode{T, E} 
    id::Int
    
    parent::Union{Branch{T, E}, Nothing}

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

mutable struct RTreeIndex{T, E} <: AbstractSpatialIndex{T, E}
    nelem::Int
    root::AbstractNode{T, E}
    next_id::Int   # DO NOT ACCESS DIRECTLY - use next_id!(index)

    update_strategy::RTreeUpdateStrategy
end
RTreeIndex{T, E}() where {T, E} = RTreeIndex{T, E}(OrdinaryRTreeUpdateStrategy())
RTreeIndex{T, E}(update_strategy) where {T, E} = RTreeIndex{T, E}(0, Leaf{T, E}(1), 1, update_strategy)

Base.isempty(index::RTreeIndex) = length(index) == 0
Base.length(index::RTreeIndex) = index.nelem
Base.eltype(::RTreeIndex{T, E}) where {T, E} = E
tree_height(index::RTreeIndex) = level(index.root)
function next_id!(index)
    index.next_id += 1
    return index.next_id
end