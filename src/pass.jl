using IRTools
using IRTools: IR, isexpr, @dynamo
using LinearAlgebra

@dynamo function (b::Buffer)(args...)
  ir = IR(args...)
  ir == nothing && return
  recurse!(ir)
  return ir
end

(buf::Buffer)(::Type{Array{T,N}}, ::UndefInitializer, d::Vararg{Int,N}) where {T,N} =
  alloc(buf, Array{T,N}, d)

# Some definitions we're not interested in
# Limits compilation and avoids some perf traps

for f in [:, getproperty, LinearAlgebra.mul!, Base.promote_op, size, Base.to_shape,
          Broadcast.broadcasted, Broadcast.instantiate, Broadcast.preprocess,
          Broadcast.combine_eltypes, copyto!, Broadcast.copyto_nonleaf!,
          Broadcast.axes]
  @eval @inline (::Buffer)(::typeof($f), a...) = $f(a...)
end

(::Buffer)(::typeof(convert), ::Type{T}, x::T) where T = convert(T, x)

(buf::Buffer)(::typeof(similar), bc::Broadcast.Broadcasted{Broadcast.DefaultArrayStyle{N}},
              ::Type{T}) where {T,N} =
  alloc(buf, Array{T,N}, length.(Broadcast.axes(bc)))
