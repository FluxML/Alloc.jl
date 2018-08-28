using IRTools
using IRTools: IR, Argument, isexpr

function pass(ir)
  for (x, st) in ir
    (isexpr(st.expr, :call) && !IRTools.isprimitive(ir, st.expr.args[1])) || continue
    ir[x] = Expr(:call, Argument(1), st.expr.args...)
  end
  return ir
end

# Test / example function
@generated function (b::Buffer)(f, args...)
  m = IRTools.meta(Tuple{f,args...})
  ir = IR(m)
  ir = IRTools.spliceargs!(m, ir, (Symbol("#buf#"),Any))
  ir = pass(ir)
  ir = IRTools.varargs!(m, ir, 2)
  IRTools.argnames!(m, Symbol("#buf#"), :f, :args)
  return IRTools.update!(m, ir)
end
