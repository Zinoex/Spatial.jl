export AbstractNode, Branch, Leaf, RTree
export level, tree_height


abstract type AbstractNode{T, E} end
has_mbr(node::AbstractNode) = true
mbr(node::AbstractNode) = node.mbr

struct Branch{T, VT<:AbstractHyperrectangle{T}, E, VC<:AbstractVector{<:AbstractNode{T, E}}} <: AbstractNode{T, E} 
    parent::Union{Branch{T, E}, Nothing}
    level::Int

    mbr::VT
    children::VC  # Either you have more branches or you only have leaves as children
end
level(node::Branch) = node.level
Base.length(node::Branch) = length(node.children)

struct Leaf{T, VT<:AbstractHyperrectangle{T}, E, VE<:AbstractVector{E}} <: AbstractNode{T, E} 
    parent::Union{Branch{T, E}, Nothing}

    mbr::Union{VT, Nothing}
    data::VE  # Vector of data elements
end
level(node::Leaf) = 1
Base.length(node::Leaf) = length(node.data)

@kwdef mutable struct RTree{T, E} <: AbstractSpatialIndex{T, E}
    nelem::Int = 0
    root::AbstractNode{T, E} = Leaf{}

    branch_capacity::Integer = 100
    leaf_capacity::Integer = 100

    fill_factor::Float64 = 0.7
    split_factor::Float64 = 0.4
    reinsert_factor::Float64 = 0.3
end

Base.isempty(index::RTree) = length(index) == 0
Base.length(index::RTree) = index.nelem
Base.eltype(::RTree{T, E}) where {T, E} = E
tree_height(index::RTree) = level(index.root)