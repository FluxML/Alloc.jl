# Alloc.jl

Alloc.jl makes Julia's memory allocator customisable. Currently it provides the ability to bump allocate everything within a block of code.

```julia
julia> using IRTools

julia> using Alloc: Buffer, run, profile

julia> function f()
         x = rand(100, 100)
         y = rand(100)
         x*y
       end
f (generic function with 1 method)

julia> @allocated f()
81872

julia> profile(f); # Figure out how big our buffer should be
[ Info: Allocated 81600 bytes

julia> const buf = Buffer(10^6);

julia> @allocated run(f, buf)
1280
```

The bump allocator has the downside that no memory is ever freed until `f` is finished. The advantage is that allocation is _really_ fast (effectively the same as stack allocation of arrays), so if your memory usage is reasonably predictable you can just bump allocate within your main loop.
