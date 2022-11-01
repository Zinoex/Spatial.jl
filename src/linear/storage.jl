export LinearIndex

mutable struct LinearIndex{T, E, VE<:AbstractVector{E}} <: AbstractSpatialIndex{T, E}
    container::VE
end
LinearIndex{T}(container::VE) where {T, VE<:AbstractVector} = LinearIndex{T, eltype(VE), VE}(container)
LinearIndex{T, E}() where {T, E} = LinearIndex{T, E, Vector{E}}(Vector{E}())

function bulk_load!(index::LinearIndex{T, E, VE}, data::VE) where {T, E, VE<:AbstractVector{E}}
    index.container = copy(data)
end

Base.isempty(index::LinearIndex) = isempty(index.container)
Base.length(index::LinearIndex) = length(index.container)
Base.eltype(::LinearIndex{T, E, VE}) where {T, E, VE} = E
