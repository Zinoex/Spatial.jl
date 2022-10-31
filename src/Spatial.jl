module Spatial

using LazySets

include("index.jl")
include("query.jl")

# Index types
include("linear/linear.jl")
end
