

# If the data is not hyperrectangular, we may over-approximate
# it and wrap in this class
@kwdef struct SpatialElem{T, VT<:AbstractHyperrectangle{T}, E}
    data::E
    mbr::VT
end
function SpatialElem(data) 
    @assert has_mbr(data)

    SpatialElem(data, mbr(data))
end

has_mbr(elem::SpatialElem) = true
mbr(elem::SpatialElem) = elem.mbr
region(elem::SpatialElem) = region(elem.data)
data(elem::SpatialElem{V, VT, E}) = elem.data

# While a LazySet natively supports mbr (for bounded sets), we recommend
# to wrap it in SpatialElem to avoid recomputing for every query
has_mbr(elem::LazySet) = isbounded(elem)
mbr(elem::LazySet) = box_approximation(elem)
region(elem::LazySet) = elem

function join_mbr(mbrs::VVT) where {T, VT<:AbstractHyperrectangle{T}, VVT<:AbstractVector{VT}}
    min_low = min.(low.(mbrs)...)
    max_high = max.(high.(mbrs)...)

    return hyperrectangle(VT, min_low, max_high)
end

hyperrectangle(Hyperrectangle{T}, low, high) where {T} = Hyperrectangle(low=low, high=high)