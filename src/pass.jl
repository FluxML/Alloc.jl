using IRTools
using IRTools: IR, Argument, isexpr
using LinearAlgebra

function pass(ir)
  for (x, st) in ir
    (isexpr(st.expr, :call) && !IRTools.isprimitive(ir, st.expr.args[1])) || continue
    ir[x] = Expr(:call, Argument(1), st.expr.args...)
  end
  return ir
end

@generated function (b::Buffer)(f, args...)
  m = IRTools.meta(Tuple{f,args...})
  m == nothing && return :(f(args...))
  # Core.println((f, args...))
  ir = IR(m)
  ir = IRTools.spliceargs!(m, ir, (Symbol("#buf#"),Any))
  ir = pass(ir)
  ir = IRTools.varargs!(m, ir, 2)
  IRTools.argnames!(m, Symbol("#buf#"), :f, :args)
  return IRTools.update!(m, ir)
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
