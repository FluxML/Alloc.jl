using Alloc, Test
using Alloc: allocated

r = allocated() do
  x = rand(5, 5)
  y = rand(5)
  x*y
end

@test r == sizeof(rand(5,5))+sizeof(rand(5))*2
