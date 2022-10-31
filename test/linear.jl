using Test
using Spatial
using LazySets

@testset "LinearIndex" begin
    elems = [rand(Hyperrectangle, dim=3) for _ in 1:10]
    spatial_elems = [SpatialElem(region, mbr(region)) for region in elems]
    index = LinearIndex{Float64}(spatial_elems)

    f = ((a, b),) -> a == region(b)
    @test all(f, zip(elems, index))
end