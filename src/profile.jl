export mprofile
using Cassette
using Cassette: @context, overdub
@context ProfileCtx

function Cassette.prehook(cx::ProfileCtx, ::Type{Array{T, N}}, ::UndefInitializer, d::Vararg{Int, N}) where {T, N}
    isbitstype(T) || return
    cx.metadata[] += sizeof(T) * prod(d)
    return
end

function Cassette.prehook(cx::ProfileCtx, ::typeof(similar), bc::Broadcast.Broadcasted{Broadcast.DefaultArrayStyle{N}}, ::Type{T}) where {T, N}
    isbitstype(T) || return
    d = length.(Broadcast.axes(bc))
    cx.metadata[] += sizeof(T) * prod(d)
    return
end

function mprofile(f)
  ctx = ProfileCtx(metadata = Ref(0))
  x = overdub(ctx, f)
  return x, ctx.metadata[]
end

const _FIRST_EXEC_CHECK_ = IdDict{Any, Buffer}()

function hoist_alloc(f)
  if haskey(_FIRST_EXEC_CHECK_, f)
      return hoist_alloc(f, _FIRST_EXEC_CHECK_[f])
  else
      ret, sz = mprofile(f)
      _FIRST_EXEC_CHECK_[f] = Buffer(sz)
      return ret
  end
end

Cassette.@context TraceCtx

mutable struct Trace
  current::Vector{Any}
  stack::Vector{Any}
  Trace() = new([], [])
end

function enter!(t::Trace, f, args...)
  b = @allocated f(args...)
  pair = (f, args, b) => Any[]
  push!(t.current, pair)
  push!(t.stack, t.current)
  t.current = pair.second
  return nothing
end

function exit!(t::Trace)
  t.current = pop!(t.stack)
  return nothing
end

Cassette.prehook(ctx::TraceCtx, f, args...) = enter!(ctx.metadata, f, args...)
Cassette.posthook(ctx::TraceCtx, f, args...) = exit!(ctx.metadata)

export trace
function trace(f)
  ctx = TraceCtx(metadata=Trace())
  Cassette.overdub(ctx, f)
  return ctx.metadata.current
end
