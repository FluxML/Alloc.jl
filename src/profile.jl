using IRTools: @dynamo, recurse!

mutable struct ProfileCtx
  bytes::Int
end

@dynamo function (cx::ProfileCtx)(args...) where {T,N}
  ir = IR(args...)
  ir == nothing && return
  recurse!(ir)
  return ir
end

function (cx::ProfileCtx)(::Type{Array{T,N}}, ::UndefInitializer, d::Vararg{Int,N}) where {T,N}
  cx.bytes += sizeof(T)*prod(d)
  Array{T,N}(undef, d)
end

function profile(f)
  cx = ProfileCtx(0)
  x = cx(f)
  @info "Allocated $(cx.bytes) bytes"
  return x
end

function allocated(f)
  cx = ProfileCtx(0)
  cx(f)
  return cx.bytes
end
