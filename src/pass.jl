export hoist_alloc, Buffer
using Zygote

using Cassette, LinearAlgebra
using Cassette: @context, overdub

@context BuffCtx

function hoist_alloc(f, b::Buffer)
    clear!(b)
    return overdub(BuffCtx(metadata=b), f)
end

# Cassette.prehook(ctx::BuffCtx, f, args...) = println(typeof(f), "  ", typeof(args))

@inline function Cassette.overdub(ctx::BuffCtx, ::typeof(similar), bc::Broadcast.Broadcasted{Broadcast.DefaultArrayStyle{N}}, ::Type{T}) where {T, N}
    isbitstype(T) || return similar(bc, T)
    return alloc(ctx.metadata, Array{T, N}, length.(Broadcast.axes(bc)))
end

# NOTE: should use inferred type of similar instead? or just do overloading
@inline function Cassette.overdub(ctx::BuffCtx, ::typeof(similar), X::AbstractArray, ::Type{T}, dims::Dims{N}) where {T, N}
    isbitstype(T) || return similar(X, T, dims)
    return alloc(ctx.metadata, Array{T, N}, dims)
end

@inline function Cassette.overdub(ctx::BuffCtx, ::typeof(similar), X::AbstractArray{T}, dims::Dims{N}) where {T, N}
    isbitstype(T) || return similar(X, T, dims)
    return alloc(ctx.metadata, Array{T, N}, dims)
end

@inline function Cassette.overdub(ctx::BuffCtx, ::typeof(copy), X::Array{T, N}) where {T, N}
    isbitstype(T) || return copy(X)
    new = alloc(ctx.metadata, Array{T, N}, size(X))
    copyto!(new, X)
    return new
end

@inline function Cassette.overdub(ctx::BuffCtx, ::Type{Array{T, N}}, ::UndefInitializer, d::Vararg{Int, N}) where {T, N}
    isbitstype(T) || return Array{T, N}(undef, d)
    T === UInt8 && return Array{T, N}(undef, d) # make Zygote stack happy
    return alloc(ctx.metadata, Array{T, N}, d)
end

const _WHITE_LIST_ = Set([
    LinearAlgebra.mul!,
    Base.promote_op, Base.to_shape, Core.getfield,
    Core.:(===), Base.getproperty, Zygote.Grads, Base.iterate,
    Broadcast.broadcasted, Broadcast.instantiate,
    Broadcast.preprocess, Base.not_int, Zygote.cache,
    Zygote.tailmemaybe, Base.size,
    Core.tuple, Zygote.literal_getproperty,
    Broadcast.combine_eltypes, copyto!,
    Broadcast.copyto_nonleaf!,
    Broadcast.axes, Base.getindex,
    Base.setindex!, Base.fill!,
    Zygote._push!,
    Base.length,
    ])

for F in _WHITE_LIST_
    @eval @inline Cassette.overdub(ctx::BuffCtx, f::typeof($F), xs...) = f(xs...)
    @eval @inline Cassette.overdub(ctx::BuffCtx, ::typeof(Zygote._forward), zctx::Zygote.Context, f::typeof($F), xs...) = Zygote._forward(zctx, f, xs...)
end

@eval Cassette.overdub(ctx::BuffCtx, ::Type{T}, xs...) where {T <:Union{Transpose, Adjoint}} = T(xs...)
@eval Cassette.overdub(ctx::BuffCtx, ::Type{T}, xs...) where {T <:Zygote.Pullback} = T(xs...)
