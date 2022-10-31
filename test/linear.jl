using Test
using Spatial
using LazySets

@testset "LinearIndex" begin
    split = LinRange(0.0, 10.0, 11)
    elems = [Hyperrectangle(low=[low], high=[high]) for (low, high) in zip(split[1:end - 1], split[2:end])]
    spatial_elems = [SpatialElem(region, mbr(region)) for region in elems]
    index = LinearIndex{Float64}(spatial_elems)

    # Test that the iterator over LinearIndex works as anticipated
    @test length(index) == length(spatial_elems)
    @test all([region(b) ∈ elems for b in index])

    # Test PointQuery with Singleton LazySets
    # Also works to test findfirst of LinearIndex
    query = PointQuery(Singleton([5.5]))
    res = Spatial.findfirst(query, index)

    @test low(region(res), 1) ≈ 5.0
    @test high(region(res), 1) ≈ 6.0

    # Test PointQuery without wrapping in the Singleton
    query = PointQuery([6.5])
    res = Spatial.findfirst(query, index)

    @test low(region(res), 1) ≈ 6.0
    @test high(region(res), 1) ≈ 7.0

    # Test PointQuery outside the index
    query = PointQuery([-1.0])
    res = Spatial.findfirst(query, index)

    @test isnothing(res)

    # Test findall non-empty
    query = PointQuery(Singleton([5.5]))
    res = collect(Spatial.findall(query, index))

    @test length(res) == 1

    @test low(region(res[1]), 1) ≈ 5.0
    @test high(region(res[1]), 1) ≈ 6.0

    # Test findall empty
    query = PointQuery(Singleton([-1.0]))
    res = collect(Spatial.findall(query, index))

    @test length(res) == 0

    # Test RegionConstainsQuery - 2 elements wide
    query = RegionConstainsQuery(Hyperrectangle(low=[0.5], high=[3.5]))
    res = collect(Spatial.findall(query, index))

    @test length(res) == 2

    @test low(region(res[1]), 1) ≈ 1.0
    @test high(region(res[1]), 1) ≈ 2.0

    @test low(region(res[2]), 1) ≈ 2.0
    @test high(region(res[2]), 1) ≈ 3.0

    # Test RegionConstainsQuery - smaller than elements
    query = RegionConstainsQuery(Hyperrectangle(low=[0.5], high=[1.0]))
    res = collect(Spatial.findall(query, index))

    @test length(res) == 0

    # Test RegionSubsetQuery - too large
    query = RegionSubsetQuery(Hyperrectangle(low=[0.5], high=[3.5]))
    res = collect(Spatial.findall(query, index))

    @test length(res) == 0

    # Test RegionSubsetQuery - fits within one element
    query = RegionSubsetQuery(Hyperrectangle(low=[4.5], high=[5.0]))
    res = collect(Spatial.findall(query, index))

    @test length(res) == 1

    @test low(region(res[1]), 1) ≈ 4.0
    @test high(region(res[1]), 1) ≈ 5.0

    # Test RegionIntersectsQuery - intersects two elements
    query = RegionIntersectsQuery(Hyperrectangle(low=[4.5], high=[5.5]))
    res = collect(Spatial.findall(query, index))

    @test length(res) == 2

    @test low(region(res[1]), 1) ≈ 4.0
    @test high(region(res[1]), 1) ≈ 5.0

    @test low(region(res[2]), 1) ≈ 5.0
    @test high(region(res[2]), 1) ≈ 6.0
end