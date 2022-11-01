export AbstractQuery, AbstractSpatialQuery
export findfirst, findall
export PointQuery, RegionConstainsQuery, RegionSubsetQuery, RegionIntersectsQuery
export is_mbr_disjoint

# Generic queries may also select based on non-spatial properties (e.g. id, name, etc.).
# As a result, they may not be efficient.
abstract type AbstractQuery end
struct AllQuery <: AbstractQuery end
satisfy(query::AllQuery, elem) = true

# Spatial queries that may exploit the geometric properties of index and query.
abstract type AbstractSpatialQuery{T} end
has_mbr(query::AbstractSpatialQuery) = true
# All spatial queries must implement mbr and region

### Point query
struct PointQuery{T, VT<:AbstractSingleton{T}} <: AbstractSpatialQuery{T}
    point::VT
end
PointQuery(point::VT) where {T, VT<:AbstractVector{T}} = PointQuery(Singleton(point))

mbr(query::PointQuery) = query.point
region(query::PointQuery) = query.point
function satisfy(query::PointQuery, elem)
    if has_mbr(elem) && element(mbr(query)) ∉ mbr(elem)
        return false
    end

    return element(region(query)) ∈ region(elem)
end

##################
# Region queries # 
##################
is_mbr_disjoint(query, elem) = has_mbr(elem) && isdisjoint(mbr(query), mbr(elem))

### elem ∈ region query
struct RegionConstainsQuery{T, VT<:LazySet{T}, VM<:AbstractHyperrectangle{T}} <: AbstractSpatialQuery{T}
    region::VT
    mbr::VM
end
RegionConstainsQuery(region) = RegionConstainsQuery(region, box_approximation(region))

mbr(query::RegionConstainsQuery) = query.mbr
region(query::RegionConstainsQuery) = query.region
function satisfy(query::RegionConstainsQuery, elem)
    if is_mbr_disjoint(query, elem)
        return false
    end

    return region(elem) ⊆ region(query)
end

### region ∈ elem query
struct RegionSubsetQuery{T, VT<:LazySet{T}, VM<:AbstractHyperrectangle{T}} <: AbstractSpatialQuery{T}
    region::VT
    mbr::VM
end
RegionSubsetQuery(region) = RegionSubsetQuery(region, box_approximation(region))

mbr(query::RegionSubsetQuery) = query.mbr
region(query::RegionSubsetQuery) = query.region
function satisfy(query::RegionSubsetQuery, elem) 
    if is_mbr_disjoint(query, elem)
        return false
    end

    return region(query) ⊆ region(elem)
end

### elem ∩ region ≠ ∅ query
struct RegionIntersectsQuery{T, VT<:LazySet{T}, VM<:AbstractHyperrectangle{T}} <: AbstractSpatialQuery{T}
    region::VT
    mbr::VM
end
RegionIntersectsQuery(region) = RegionIntersectsQuery(region, box_approximation(region))

mbr(query::RegionIntersectsQuery) = query.mbr
region(query::RegionIntersectsQuery) = query.region
function satisfy(query::RegionIntersectsQuery, elem) 
    if is_mbr_disjoint(query, elem)
        return false
    end

    return !isdisjoint(region(elem), region(query))
end