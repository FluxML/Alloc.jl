module Alloc

using Cassette
import Cassette: @context, overdub, execute, prehook

include("profile.jl")
include("stack.jl")
include("pass.jl")

end # module
