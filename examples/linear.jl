using Spatial
using LazySets

using BenchmarkTools

elems = [translate(rand(Hyperrectangle, dim=3), randn(3) .* 100) for _ in 1:1000000]
spatial_elems = [SpatialElem(region, mbr(region)) for region in elems]

index = LinearIndex{Float64, SpatialElem{Float64}}()
@time bulk_load!(index, spatial_elems)

query = PointQuery([2.5, 2.0, 1.0])
@benchmark Spatial.findall(query, index)