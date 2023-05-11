using Test
using Spatial
using LazySets

@testset "Spatial" begin
    @time @testset "Spatial.Linear" begin include("linear.jl") end
    @time @testset "Spatial.RTree" begin include("rtree.jl") end
end
