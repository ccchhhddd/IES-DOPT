include("TransferFunction.jl")

"""
某输出基于某输入的传递函数对应的状态空间
"""
struct StateSpace
    states::Int64
    A
    B
    C
    D
end

"""
状态矩阵
"""
function state_matrix(g::Fraction)
    n = g.denominator.num_of_items - 1# 系统状态量个数
    if n == 0
        # 此时系统可能为比例环节,或0,返回空矩阵
        return []
    else
        # 直接分解法下的状态矩阵
        A = zeros(n, n)
        for j = 1:n
            A[n, j] = -g.denominator.coefficients[j]
            j == 1 && continue
            A[j-1, j] = 1
        end
    end
    return A
end

"""
输入矩阵
"""
function input_matrix(g::Fraction)
    n = g.denominator.num_of_items - 1# 系统状态量个数
    if n == 0
        return []
    else
        B = zeros(n, 1)
        B[end, 1] = 1
        return B
    end
end

"""
输出矩阵
"""
function output_matrix(g::Fraction)
    n = g.denominator.num_of_items - 1
    if n == 0
        return []
    else
        C = zeros(1, n)
        # 分子分母如果齐次,取出分子最高项系数(分母最高项为1),反之取0
        s = n == g.numerator.num_of_items - 1 ? g.numerator.coefficients[end] : 0
        for i = 1:n
            if i <= g.numerator.num_of_items
                C[1, i] = g.numerator.coefficients[i] - s * g.denominator.coefficients[i]
            else
                C[1, i] = 0
            end
        end
        return C
    end
end

"""
直接传输矩阵(系数)
"""
function direct_transmission_matrix(g::Fraction)
    D = zeros(1, 1)
    if g.denominator.num_of_items == g.numerator.num_of_items
        D[1, 1] = g.numerator.coefficients[end]
    end
    return D
end

StateSpace(g::Fraction) = StateSpace(
    g.denominator.num_of_items - 1,
    state_matrix(g),
    input_matrix(g),
    output_matrix(g),
    direct_transmission_matrix(g)
)

nothing