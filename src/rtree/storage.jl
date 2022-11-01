export AbstractNode, Branch, Leaf, RTreeIndex
export level, tree_height, isroot
export RTreeUpdateStrategy, OrdinaryRTreeUpdateStrategy

abstract type AbstractNode{T, E} end
has_mbr(node::AbstractNode) = true
mbr(node::AbstractNode) = node.mbr
isroot(node::AbstractNode) = isnothing(node.parent)

Base.@kwdef mutable struct Branch{T, VT<:AbstractHyperrectangle{T}, E, VC<:AbstractVector{<:AbstractNode{T, E}}} <: AbstractNode{T, E} 
    parent::Union{Branch{T, E}, Nothing} = nothing
    level::Int

    mbr::VT
    children::VC  # Either you have more branches or you only have leaves as children
end
level(node::Branch) = node.level
Base.length(node::Branch) = length(node.children)

Base.@kwdef mutable struct Leaf{T, VT<:AbstractHyperrectangle{T}, E, VE<:AbstractVector{E}} <: AbstractNode{T, E} 
    parent::Union{Branch{T, E}, Nothing} = nothing

    mbr::Union{VT, Nothing}
    data::VE  # Vector of data elements
end
level(node::Leaf) = 1
Base.length(node::Leaf) = length(node.data)


abstract type RTreeUpdateStrategy end

Base.@kwdef struct OrdinaryRTreeUpdateStrategy <: RTreeUpdateStrategy
    branch_capacity = 100
    leaf_capacity = 100

    min_fill = 0.4   # percentage
end

Base.@kwdef mutable struct RTreeIndex{T, E} <: AbstractSpatialIndex{T, E}
    nelem::Int = 0
    root::AbstractNode{T, E} = Leaf{T, Hyperrectangle{T}, E, Vector{E}}(nothing, nothing, Vector{E}())

    update_strategy::RTreeUpdateStrategy = OrdinaryRTreeUpdateStrategy()
end
RTreeIndex(nelem, root) = RTreeIndex(nelem, root, OrdinaryRTreeUpdateStrategy())

Base.isempty(index::RTreeIndex) = length(index) == 0
Base.length(index::RTreeIndex) = index.nelem
Base.eltype(::RTreeIndex{T, E}) where {T, E} = E
tree_height(index::RTreeIndex) = level(index.root)