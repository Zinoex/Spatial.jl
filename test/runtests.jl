using Test
using Spatial
using LazySets

@testset "Spatial.jl" begin
    include("linear.jl")
    include("rtree.jl")
end
