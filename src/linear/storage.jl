export LinearIndex

mutable struct LinearIndex{T, E} <: AbstractSpatialIndex{T, E}
    container::AbstractVector{E}
end
LinearIndex{T}(container::VE) where {T, E, VE<:AbstractVector{E}} = LinearIndex{T, E}(container)
LinearIndex{T, E}() where {T, E} = LinearIndex{T, E}(Vector{E}())

function bulk_load!(index::LinearIndex, data::AbstractVector)
    index.container = copy(data)
end

Base.isempty(index::LinearIndex) = isempty(index.container)
Base.length(index::LinearIndex) = length(index.container)
Base.eltype(::LinearIndex{T, E}) where {T, E} = E
