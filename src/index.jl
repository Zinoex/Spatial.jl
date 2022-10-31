export AbstractSpatialIndex, SpatialElem, has_mbr, mbr, region

abstract type AbstractSpatialIndex{T, E} end

# Indices of subtypes of AbstractSpatialIndex should implement:
# - Base.isempty
# - Base.length
# - Base.eltype
# - Base.iterate
# 
# - findfirst(query, index)
# - findall(query, index)
# We don't adapt this to Base.findfirst and Base.findall as
# they return indices, and we want the element instead.

# If the data is not hyperrectangular, we may over-approximate
# it and wrap in this class
struct SpatialElem{T, VT<:AbstractHyperrectangle{T}, E}
    data::E
    mbr::VT
end
has_mbr(elem::SpatialElem) = true
mbr(elem::SpatialElem) = elem.mbr
region(elem::SpatialElem) = region(elem.data)

# While a LazySet natively supports mbr (for bounded sets), we recommend
# to wrap it in SpatialElem to avoid recomputing for every query
has_mbr(elem::LazySet) = isbounded(elem)
mbr(elem::LazySet) = box_approximation(elem)
region(elem::LazySet) = elem