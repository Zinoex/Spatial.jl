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
abstract type AbstractSpatialQuery{T} <: AbstractQuery end
has_mbr(query::AbstractSpatialQuery) = !isnothing(mbr(query))
mbr(query::AbstractSpatialQuery) = query.mbr
region(query::AbstractSpatialQuery) = query.region
# All spatial queries must have a region and mbr field, although mbr may be nothing

### Point query
struct PointQuery{T} <: AbstractSpatialQuery{T}
    point::AbstractSingleton{T}
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
is_mbr_disjoint(query, elem) = has_mbr(query) && has_mbr(elem) && isdisjoint(mbr(query), mbr(elem))

### elem ∈ region query
struct RegionConstainsQuery{T} <: AbstractSpatialQuery{T}
    region::LazySet{T}
    mbr::Union{Nothing, AbstractHyperrectangle{T}}
end
function RegionConstainsQuery(region) 
    if isbounded(region)
        return RegionConstainsQuery(region, box_approximation(region))
    else
        return RegionConstainsQuery(region, nothing)
    end
end

function satisfy(query::RegionConstainsQuery, elem)
    if is_mbr_disjoint(query, elem)
        return false
    end

    return region(elem) ⊆ region(query)
end

### region ∈ elem query
struct RegionSubsetQuery{T} <: AbstractSpatialQuery{T}
    region::LazySet{T}
    mbr::Union{Nothing, AbstractHyperrectangle{T}}
end
function RegionSubsetQuery(region) 
    if isbounded(region)
        return RegionSubsetQuery(region, box_approximation(region))
    else
        return RegionSubsetQuery(region, nothing)
    end
end

function satisfy(query::RegionSubsetQuery, elem) 
    if is_mbr_disjoint(query, elem)
        return false
    end

    return region(query) ⊆ region(elem)
end

### elem ∩ region ≠ ∅ query
struct RegionIntersectsQuery{T} <: AbstractSpatialQuery{T}
    region::LazySet{T}
    mbr::Union{Nothing, AbstractHyperrectangle{T}}
end
function RegionIntersectsQuery(region) 
    if isbounded(region)
        return RegionIntersectsQuery(region, box_approximation(region))
    else
        return RegionIntersectsQuery(region, nothing)
    end
end

function satisfy(query::RegionIntersectsQuery, elem) 
    if is_mbr_disjoint(query, elem)
        return false
    end

    return !isdisjoint(region(elem), region(query))
end