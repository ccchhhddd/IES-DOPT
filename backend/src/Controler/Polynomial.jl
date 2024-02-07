"""
多项式结构体,储存多项式系数向量,按幂次升序.
"""
Base.@kwdef struct Polynomial1
    coefficients::Vector{<:Number} = [0]
    num_of_items::Int64 = 1
end

Polynomial1(x::Vector{<:Number}) = Polynomial1(x, length(x))

"""
打印多项式,默认变量为x
"""
function Base.show(io::IO, x::Polynomial1)
    s = ""
    for i in eachindex(x.coefficients)
        x.coefficients[i] == 0 && continue
        if i > 2
            if x.coefficients[i] == 1
                term = "x^$(i-1)"
            else
                term = "$(x.coefficients[i])*x^$(i-1)"
            end
        elseif i == 2
            term = "$(x.coefficients[i])*x"
        else
            term = "$(x.coefficients[i])"
        end
        s == "" ? s *= term : s *= " + " * term
    end
    println(io, s == "" ? "0" : s)
end

"""
多项式求导
"""
function der(x::Polynomial1)
    n = length(x.coefficients)
    return n == 1 ? Polynomial1() : Polynomial1([(i - 1) * x.coefficients[i] for i in eachindex(x.coefficients)[2:end]])
end

"""
多项式比大小
"""
function Base.max(x::Polynomial1, y::Polynomial1)
    if x.num_of_items >= y.num_of_items
        return x
    else
        return y
    end
end
function Base.min(x::Polynomial1, y::Polynomial1)
    if x.num_of_items >= y.num_of_items
        return y
    else
        return x
    end
end

"""
多项式乘法
"""
function Base.:*(x::Polynomial1, y::Polynomial1)
    n = x.num_of_items + y.num_of_items - 2
    new = Number[]
    for i = 0:n
        s = 0
        for j = 0:i
            (j + 1 > x.num_of_items || i - j + 1 > y.num_of_items) && continue
            s += x.coefficients[j+1] * y.coefficients[i-j+1]
        end
        push!(new, s)
    end
    return Polynomial1(new, n + 1)
end
Base.:*(x::Number, y::Polynomial1) = Polynomial1(x * y.coefficients)
Base.:*(x::Polynomial1, y::Number) = y * x

"""
定义分式
"""
struct Fraction1
    numerator::Polynomial1
    denominator::Polynomial1
end
Fraction1(x::Vector{<:Number}, y::Vector{<:Number}) = Fraction1(Polynomial1(x), Polynomial1(y))

"""
打印分式
"""
function Base.show(io::IO, x::Fraction1)
    show(io, x.numerator)
    println(io, repeat("-", 7 * length(x.denominator.coefficients)))
    show(io, x.denominator)
end

"""
分式约分
"""
reduction(x::Polynomial1) = x
function reduction(x::Fraction1)
    if x.numerator.num_of_items == x.denominator.num_of_items
        if x.numerator.coefficients ≈ x.denominator.coefficients
            return Polynomial1([1])
        else
            return x
        end
    end
    return x
end

"""
多项式除法
"""
Base.:/(x::Polynomial1, y::Polynomial1) = reduction(Fraction1(x, y))
Base.:/(x::Polynomial1, y::Number) = Polynomial1(x.coefficients / y)
Base.:/(x::Number, y::Polynomial1) = Fraction1([x], y.coefficients)

"""
分式乘除法,考虑约分的情况,我们以除法为主
"""
Base.:/(x::Fraction1, y::Fraction1) = reduction(x.numerator / y.numerator * (y.denominator / x.denominator))
Base.:/(x::Fraction1, y::Polynomial1) = reduction(Fraction1(x.numerator / y, x.denominator))
Base.:/(x::Polynomial1, y::Fraction1) = reduction(x / y.numerator * y.denominator)
function Base.:*(x::Fraction1, y::Fraction1)
    x1 = x.numerator / y.denominator
    y1 = y.numerator / x.denominator
    return reduction(Fraction1(x1.numerator * y1.numerator, x1.denominator * y1.denominator))
end
function Base.:*(x::Fraction1, y::Polynomial1)
    y₁ = y / x.denominator
    return reduction(Fraction1(x.numerator * y₁.numerator, y₁.denominator))
end
Base.:*(x::Polynomial1, y::Fraction1) = reduction(y * x)
Base.:*(x::Fraction1, y::Number) = reduction(Fraction1(x.numerator * y, x.denominator))
Base.:*(x::Number, y::Fraction1) = reduction(y * x)

"""
多项式及分式加减法
"""
function Base.:+(x::Polynomial1, y::Polynomial1)
    m = max(x, y)
    n = min(x, y)
    new = [n.coefficients + m.coefficients[1:n.num_of_items]; m.coefficients[n.num_of_items+1:end]]
    return Polynomial1(new, m.num_of_items)
end
Base.:+(x::Number, y::Polynomial1) = Polynomial1([x]) + y
Base.:+(x::Polynomial1, y::Number) = y + x
Base.:+(x::Fraction1, y::Polynomial1) = reduction(Fraction1(x.numerator + y * x.denominator, x.denominator))
Base.:+(x::Polynomial1, y::Fraction1) = reduction(Fraction1(y.numerator + y.denominator * x, y.denominator))
Base.:+(x::Fraction1, y::Fraction1) = reduction(Fraction1(x.numerator * y.denominator + x.denominator * y.numerator, x.denominator * y.denominator))
Base.:+(x::Number, y::Fraction1) = reduction(Fraction1(x * y.denominator + y.numerator, y.denominator))
Base.:+(x::Fraction1, y::Number) = reduction(y + x)
Base.:-(x::Polynomial1, y::Polynomial1) = x + -1 * y
Base.:-(x::Polynomial1, y::Number) = x + -1 * y
Base.:-(x::Number, y::Polynomial1) = -1 * (y - x)
Base.:-(x::Fraction1, y::Polynomial1) = reduction(Fraction1(x.numerator - y * x.denominator, x.denominator))
Base.:-(x::Polynomial1, y::Fraction1) = reduction(Fraction1(y.denominator * x - y.numerator, y.denominator))
Base.:-(x::Fraction1, y::Fraction1) = reduction(Fraction1(x.numerator * y.denominator - x.denominator * y.numerator, x.denominator * y.denominator))
Base.:-(x::Fraction1, y::Number) = reduction(Fraction1(x.numerator - x.denominator * y, x.denominator))
Base.:-(x::Number, y::Fraction1) = reduction(-1 * (y - x))

"""
多项式及分式的幂
"""
function Base.:^(x::Polynomial1, n::Int64)
    if n > 0
        s = x
        for i = 2:n
            s *= x
        end
        return s
    elseif n == 0
        return Polynomial1([1], 1)
    else
        return Fraction1(Polynomial1([1], 1), x^(-n))
    end
end
Base.:^(x::Fraction1, n::Int64) = x.numerator^n * x.denominator^n

"""
分式求导
"""
der(x::Fraction1) = (der(x.numerator) * x.denominator - x.numerator * der(x.denominator)) / x.denominator^2

"""
获取多项式的最低次数
"""
function get_min_power(x::Polynomial1)
    for i = 1:x.num_of_items
        x.coefficients[i] == 0 && continue
        return i - 1
    end
end

"""
分式化简
"""
function simplify(x::Fraction1)
    if x.numerator.coefficients[1] == 0 && x.denominator.coefficients[1] == 0
        m = get_min_power(x.numerator)
        n = get_min_power(x.denominator)
        if n <= m
            ans = Fraction1([zeros(m - n); x.numerator.coefficients[m+1:end]], x.denominator.coefficients[n+1:end])
        else
            ans = Fraction1(x.numerator.coefficients[m+1:end], [zeros(m - n); x.denominator.coefficients[n+1:end]])
        end
        return Fraction1(ans.numerator / ans.denominator.coefficients[end], ans.denominator / ans.denominator.coefficients[end])
    end
    return Fraction1(x.numerator / x.denominator.coefficients[end], x.denominator / x.denominator.coefficients[end])
end

"""
传递函数转化为状态矩阵
"""
function system_matrix(g::Vector{Fraction1})
    N = sum((x) -> x.denominator.num_of_items - 1, g)
    ans = zeros(N, N)
    l = 1
    for i = 1:length(g)
        n = g[i].denominator.num_of_items - 1
        A = zeros(n, n)
        for j = 1:n
            A[n, j] = -g[i].denominator.coefficients[j]
            j == 1 && continue
            A[j-1, j] = 1
        end
        ans[l:l+n-1, l:l+n-1] = A
        l += n
    end
    return ans
end

"""
输入矩阵
"""
function input_matrix(g::Vector{Fraction1})
    N = sum((x) -> x.denominator.num_of_items - 1, g)
    m = length(g)
    B = zeros(N, m)
    for i = 1:m
        B[sum((x) -> x.denominator.num_of_items - 1, g[1:i]), i] = 1
    end
    return B
end

"""
输出矩阵
"""
function output_matrix(g::Vector{Fraction1})
    ans = []
    for i in g
        n = i.numerator.num_of_items
        d = i.denominator.num_of_items
        if n < d
            push!(ans, [i.numerator.coefficients; zeros(d - n - 1)])
        else
            b = i.numerator.coefficients[end]
            s = i.denominator.coefficients[1:end-1]
            push!(ans, i.numerator.coefficients[1:end-1] - b * s)
        end
    end
    C = ans[1]
    for i in ans[2:end]
        C = [C; i]
    end
    return C
end

"""
直接传输矩阵
"""
function direct_transmission_matrix(g::Vector{Fraction1})
    D = Number[]
    for i in g
        if i.numerator.num_of_items < i.denominator.num_of_items
            push!(D, 0.0)
        else
            push!(D, i.numerator.coefficients[end])
        end
    end
    return D
end

nothing
