using Base: unsafe_convert

mutable struct Buffer
    buf::Vector{UInt8}
    offset::UInt
end

Buffer() = Buffer(1<<20)
Buffer(n::Int) = Buffer(Vector{UInt8}(undef, n), 0)
Base.copy(b::Buffer) = Buffer(copy(b.buf), b.offset)

function alloc(b::Buffer, ::Type{Array{T,N}}, d::NTuple{N,Int}) where {T,N}
    # @info "Allocating $(prod(d)) * $(T)"
    ptr = Base.unsafe_convert(Ptr{UInt8}, b.buf) + b.offset
    isbitstype(T) || error("cannot hoist non bitstype")
    b.offset += sizeof(T) * prod(d)
    if b.offset > length(b.buf)
        # b.buf = Vector{UInt8}(undef, proposed_offset)
        # ptr = Base.unsafe_convert(Ptr{UInt8}, b.buf) + b.offset
        error("buffer is out of memory!")
    end
    unsafe_wrap(Array, convert(Ptr{T}, ptr), d)
end

function clear!(b::Buffer)
    b.offset = 0
    return b
end
