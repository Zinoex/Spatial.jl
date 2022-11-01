module Spatial

using LazySets

include("index.jl")
include("mbr.jl")
include("query.jl")

# Index types
include("linear/linear.jl")
include("rtree/rtree.jl")
end
