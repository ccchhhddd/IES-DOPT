# 测试模块,定义了符号运算用以测试传函模块的正确性

struct Add
    f::Symbol
    l::Vector
    r::Vector
end

struct Tfs
    n::Vector
    d::Vector
end


Base.:*(x::Tfs, y::Tfs) = Tfs([x.n; y.n], [x.d; y.d])
Base.:*(x::Tfs, y::Number) = Tfs([x.n; y], x.d)
Base.:*(x::Number, y::Tfs) = y * x
function Base.:*(x::Tfs...)
    j = 1
    for k in x
        j *= k
    end
    return j
end
Base.:+(x::Tfs, y::Tfs) = Tfs([Add(:+, [x.n; y.d], [x.d; y.n])], [x.d; y.d])
Base.:+(x::Tfs, y::Number) = Tfs([Add(:+, x.n, y * x.d)], x.d)
Base.:+(x::Number, y::Tfs) = y + x
Base.:/(x::Tfs, y::Tfs) = Tfs([x.n; y.d], [x.d; y.n])
Base.:/(x::Tfs, y::Number) = Tfs(x.n, [y; x.d])
Base.:/(x::Number, y::Tfs) = Tfs([x; y.d], y.n)

function arrange(x::Vector)
    n = [1]
    s = []
    a = []
    for i = 1:length(x)
        if x[i] isa Number
            push!(n, x[i])
        elseif x[i] isa Symbol
            push!(s, x[i])
        else
            push!(a, x[i])
        end
    end
    n = *(n...)
    if n == 1
        return [s; a]
    else
        return [n; s; a]
    end
end

function Base.show(io::IO, x::Add)
    l = arrange(x.l)
    r = arrange(x.r)
    print(io, "($(l...) $(x.f) $(r...))")
    nothing
end

function Base.show(io::IO, x::Tfs)
    n = arrange(x.n)
    d = arrange(x.d)
    println(io, "$(n...)")
    println(io, repeat("-", length(d) * 6))
    println(io, "$(d...)")
    nothing
end
