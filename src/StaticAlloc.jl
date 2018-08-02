module StaticAlloc

using Cassette
import Cassette: @context, overdub, execute, prehook

include("profile.jl")
include("alloc.jl")

end # module
