using Base: unsafe_convert

mutable struct Buffer
  buf::Vector{UInt8}
  offset::UInt
end

Buffer(n::Int) = Buffer(Vector{UInt8}(undef, n),0)

function alloc(b::Buffer, ::Type{Array{T,N}}, d::NTuple{N,Int}) where {T,N}
  # @info "Allocating $(prod(d)) * $(T)"
  ptr = unsafe_convert(Ptr{UInt8}, b.buf) + b.offset
  b.offset += sizeof(T) * prod(d)
  b.offset > length(b.buf) && error("Alloc: Out of memory")
  unsafe_wrap(Array, convert(Ptr{T}, ptr), d)
end

function clear!(b::Buffer)
  b.offset = 0
  return b
end

function run(f, b::Buffer)
  clear!(b)
  return b(f)
end
