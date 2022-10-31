using Test
using Spatial
using LazySets

@testset "LinearIndex" begin
    split = LinRange(0.0, 10.0, 11)
    elems = [Hyperrectangle(low=[low], high=[high]) for (low, high) in zip(split[1:end - 1], split[2:end])]
    spatial_elems = [SpatialElem(region, mbr(region)) for region in elems]
    index = LinearIndex{Float64}(spatial_elems)

    @test all([a == region(b) for (a, b) in zip(elems, index)])

    println(split)

    query = PointQuery(Singleton([5.5]))
    res = Spatial.findfirst(query, index)

    @test low(region(res), 1) ≈ 5.0
    @test high(region(res), 1) ≈ 6.0

    query = PointQuery([6.5])
    res = Spatial.findfirst(query, index)

    @test low(region(res), 1) ≈ 6.0
    @test high(region(res), 1) ≈ 7.0
end