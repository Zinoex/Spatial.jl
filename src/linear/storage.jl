export LinearIndex

struct LinearIndex{T, E, VE<:AbstractVector{E}} <: AbstractSpatialIndex{T, E}
    container::VE
end
LinearIndex{T}(container::VE) where {T, VE<:AbstractVector} = LinearIndex{T, eltype(VE), VE}(container)

Base.isempty(index::LinearIndex) = isempty(index.container)
Base.length(index::LinearIndex) = length(index.container)
Base.eltype(::LinearIndex{T, E, VE}) where {T, E, VE} = E
