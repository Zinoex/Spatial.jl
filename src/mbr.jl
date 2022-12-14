export SpatialElem, has_mbr, mbr, region, join_mbr, hyperrectangle

# If the data is not hyperrectangular, we may over-approximate
# it and wrap in this class
struct SpatialElem{T<:Real, E}
    data::E
    mbr::AbstractHyperrectangle{T}
end
function SpatialElem(data) 
    @assert has_mbr(data)

    SpatialElem(data, mbr(data))
end

has_mbr(elem::SpatialElem) = true
mbr(elem::SpatialElem) = elem.mbr
region(elem::SpatialElem) = region(elem.data)

# While a LazySet natively supports mbr (for bounded sets), we recommend
# to wrap it in SpatialElem to avoid recomputing for every query
has_mbr(elem::LazySet) = isbounded(elem)
mbr(elem::LazySet) = box_approximation(elem)
region(elem::LazySet) = elem

function join_mbr(mbrs::VVT) where {T, VT<:AbstractHyperrectangle{T}, VVT<:AbstractVector{VT}}
    min_low = reduce((x, y) -> min.(x, y), low.(mbrs))
    max_high = reduce((x, y) -> max.(x, y), high.(mbrs))

    return hyperrectangle(VT, min_low, max_high)
end
join_mbr(mbrs::VT...) where {T, VT<:AbstractHyperrectangle{T}} = join_mbr(collect(mbrs))

hyperrectangle(::Type{Hyperrectangle{N, VNC, VNR}}, low, high) where {N, VNC<:AbstractVector{N}, VNR<:AbstractVector{N}} = Hyperrectangle(low=low, high=high)

volume(mbr::VT) where {T, VT<:AbstractHyperrectangle{T}} = prod(radius_hyperrectangle(mbr) .* 2)