export AbstractSpatialIndex
export bulk_load!

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
# 
# - Base.insert!(index, elem)
# - Base.delete!(query, index)
# - bulk_load! (from AbstractVector)