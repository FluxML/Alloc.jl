using Cassette
using Cassette: @context, overdub

@context ProfileCtx

Cassette.prehook(cx::ProfileCtx,
    ::Type{Array{T,N}}, ::UndefInitializer, d::Vararg{Int,N}) where {T,N} =
  cx.metadata[] += sizeof(T)*prod(d)

function profile(f)
  cx = ProfileCtx(metadata = Ref(0))
  x = overdub(cx, f)
  @info "Allocated $(cx.metadata[]) bytes"
  return x
end
