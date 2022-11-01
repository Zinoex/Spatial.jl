using Test
using Spatial
using LazySets

@testset "RTreeIndex" begin
    # Test node construction methods
    rect1 = Hyperrectangle(low=[1.0, 2.0], high=[3.0, 5.0])
    rect2 = Hyperrectangle(low=[2.0, 0.0], high=[4.0, 3.0])
    rect3 = Hyperrectangle(low=[6.0, 2.0], high=[7.0, 3.0])

    rect12_mbr = join_mbr(rect1, rect2)

    @test low(rect12_mbr, 1) ≈ 1.0
    @test low(rect12_mbr, 2) ≈ 0.0
    @test high(rect12_mbr, 1) ≈ 4.0
    @test high(rect12_mbr, 2) ≈ 5.0

    leaf1 = Leaf(mbr=rect12_mbr, data=[rect1, rect2])
    leaf2 = Leaf(mbr=rect3, data=[rect3])

    @test level(leaf1) == 1
    @test length(leaf1) == 2
    @test length(leaf2) == 1

    rect123_mbr = join_mbr(rect12_mbr, rect3)

    @test low(rect123_mbr, 1) ≈ 1.0
    @test low(rect123_mbr, 2) ≈ 0.0
    @test high(rect123_mbr, 1) ≈ 7.0
    @test high(rect123_mbr, 2) ≈ 5.0

    root = Branch(nothing, 1, rect123_mbr, [leaf1, leaf2])
    leaf1.parent = root
    leaf2.parent = root

    @test isroot(root)

    index = RTreeIndex(3, root)

    # Test PointQuery - in two regions
    query = PointQuery([2.5, 2.0])
    res = Spatial.findall(query, index)

    @test length(res) == 2

    @test low(region(res[1]), 1) ≈ 1.0
    @test low(region(res[1]), 2) ≈ 2.0
    @test high(region(res[1]), 1) ≈ 3.0
    @test high(region(res[1]), 2) ≈ 5.0

    @test low(region(res[2]), 1) ≈ 2.0
    @test low(region(res[2]), 2) ≈ 0.0
    @test high(region(res[2]), 1) ≈ 4.0
    @test high(region(res[2]), 2) ≈ 3.0

    # Test PointQuery - in one region
    query = PointQuery([6.5, 2.5])
    res = Spatial.findall(query, index)

    @test length(res) == 1

    @test low(region(res[1]), 1) ≈ 6.0
    @test low(region(res[1]), 2) ≈ 2.0
    @test high(region(res[1]), 1) ≈ 7.0
    @test high(region(res[1]), 2) ≈ 3.0

    # Test PointQuery - in no region
    query = PointQuery([-1.0, 1.0])
    res = Spatial.findall(query, index)

    @test length(res) == 0

    # Test RegionConstainsQuery - contains 2 regions
    query = RegionConstainsQuery(Hyperrectangle(low=[0.0, 0.0], high=[4.5, 5.5]))
    res = Spatial.findall(query, index)

    @test length(res) == 2

    @test low(region(res[1]), 1) ≈ 1.0
    @test low(region(res[1]), 2) ≈ 2.0
    @test high(region(res[1]), 1) ≈ 3.0
    @test high(region(res[1]), 2) ≈ 5.0

    @test low(region(res[2]), 1) ≈ 2.0
    @test low(region(res[2]), 2) ≈ 0.0
    @test high(region(res[2]), 1) ≈ 4.0
    @test high(region(res[2]), 2) ≈ 3.0

    # Test RegionConstainsQuery - contains 1 region and only overlaps another
    query = RegionConstainsQuery(Hyperrectangle(low=[0.0, 0.0], high=[3.5, 5.5]))
    res = Spatial.findall(query, index)

    @test length(res) == 1

    @test low(region(res[1]), 1) ≈ 1.0
    @test low(region(res[1]), 2) ≈ 2.0
    @test high(region(res[1]), 1) ≈ 3.0
    @test high(region(res[1]), 2) ≈ 5.0

    # Test RegionConstainsQuery - smaller than elements
    query = RegionConstainsQuery(Hyperrectangle(low=[0.0, 0.0], high=[3.5, 4.5]))
    res = Spatial.findall(query, index)

    @test length(res) == 0

    # Test RegionSubsetQuery - too large
    query = RegionSubsetQuery(Hyperrectangle(low=[0.0, 0.0], high=[4.5, 5.5]))
    res = Spatial.findall(query, index)

    @test length(res) == 0

    # Test RegionSubsetQuery - contained in 1 region and only overlaps another
    query = RegionSubsetQuery(Hyperrectangle(low=[2.5, 0.5], high=[3.5, 2.5]))
    res = Spatial.findall(query, index)

    @test length(res) == 1

    @test low(region(res[1]), 1) ≈ 2.0
    @test low(region(res[1]), 2) ≈ 0.0
    @test high(region(res[1]), 1) ≈ 4.0
    @test high(region(res[1]), 2) ≈ 3.0

    # Test RegionIntersectsQuery - intersects two elements
    query = RegionIntersectsQuery(Hyperrectangle(low=[0.0, 0.5], high=[4.5, 3.5]))
    res = Spatial.findall(query, index)

    @test length(res) == 2

    @test low(region(res[1]), 1) ≈ 1.0
    @test low(region(res[1]), 2) ≈ 2.0
    @test high(region(res[1]), 1) ≈ 3.0
    @test high(region(res[1]), 2) ≈ 5.0

    @test low(region(res[2]), 1) ≈ 2.0
    @test low(region(res[2]), 2) ≈ 0.0
    @test high(region(res[2]), 1) ≈ 4.0
    @test high(region(res[2]), 2) ≈ 3.0

    # # Test delete!
    # query = RegionIntersectsQuery(Hyperrectangle(low=[4.5], high=[5.5]))
    # delete!(query, index)
    # res = Spatial.findall(query, index)

    # @test length(res) == 0
    # @test length(index) == 8

    # # Test insert!
    # insert!(index, SpatialElem(Hyperrectangle(low=[4.5], high=[5.5])))
    # query = PointQuery([5.0])
    # res = Spatial.findfirst(query, index)

    # @test low(region(res), 1) ≈ 4.5
    # @test high(region(res), 1) ≈ 5.5
end