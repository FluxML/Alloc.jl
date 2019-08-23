"""
    log2i(x::Integer) -> Integer
Return log2(x), this integer version of `log2` is fast but only valid for number equal to 2^n.
"""
function log2i end

for N in [8, 16, 32, 64, 128]
    T = Symbol(:Int, N)
    UT = Symbol(:UInt, N)
    @eval begin
        log2i(x::$T) = !signbit(x) ? ($(N - 1) - leading_zeros(x)) : throw(ErrorException("nonnegative expected ($x)"))
        log2i(x::$UT) = $(N - 1) - leading_zeros(x)
    end
end
