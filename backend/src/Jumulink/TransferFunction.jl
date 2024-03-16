# 该模块用于处理控制系统方框图,利用梅森公式获取传函

include("Polynomial.jl")
include("SymbolTest.jl")

abstract type AbstractLink end
abstract type TypicalLink <: AbstractLink end
abstract type AbstractPath end

struct Input <: AbstractLink
  order::Int64
  expr::Function
end
struct Output <: AbstractLink
  order::Int64
end
struct Sum <: AbstractLink
  order::Int64
end
struct Tf <: AbstractLink
  order::Int64
  tf::Union{Fraction,Tfs}
end

function basic_input(type::String, k::Number, t::Number, x)
  if type == "阶跃输入"
    if x <= t
      return 0
    else
      return k
    end
  elseif type == "斜坡输入"
    if x <= t
      return 0
    else
      return k * (x - t)
    end
  elseif type == "抛物线输入"
    if x <= t
      return 0
    else
      return k * (x - t)^2 / 2
    end
  end
end

"""
控制系统方框图,由要素组成和它们的邻接矩阵构成.\n
使用有向图来储存拓扑关系.\n
值得注意的是:以列表示起始,以行表示终止,1代表连接,0代表没连接,-1代表和点的负输入
"""
struct SystemMap
  links::Vector{<:AbstractLink}
  adjacency_matrix::Matrix{Int8}
end

"""
方框图前向通道
"""
struct ForwardChannel <: AbstractPath
  value::Int128
  order::Int64
  links::Vector{Int16}
  tf::Union{Nothing,Tfs,Fraction}
end

"""
环路\n
易知:方框图中,环路总是可以看作从一个和点出发,然后回到该和点,当然一个和点产生的可能不止一个回路
"""
mutable struct ClosedLoop <: AbstractPath
  value::Int128
  order::Int64
  links::Vector{Int16}
  tf::Union{Fraction,Tfs,Nothing}
end

"""
利用回溯进行寻路
"""
function path_finding(matrix::Matrix, start, stop)
  # start与stop间全部的路径
  paths = []
  # 单条路径的节点栈
  path = Int16[start]
  # 前进节点
  step = start
  # 所有可能路径节点栈
  tree = []
  while true
    # 当前节点的子节点
    sons = []
    for i in eachindex(matrix[step, :])
      if matrix[step, i] != 0
        if i in path && i != start
          continue
        end
        append!(sons, i)
      end
    end
    if isempty(sons)
      if path[end] == stop
        push!(paths, copy(path))
        pop!(path)
        pop!(tree[end])
        while isempty(tree[end])
          pop!(tree)
          pop!(path)
          isempty(tree) && break
          pop!(tree[end])
        end
        isempty(tree) && break
        step = tree[end][end]
        append!(path, step)
      end
      pop!(tree[end])
      pop!(path)
      while isempty(tree[end])
        pop!(tree)
        isempty(tree) && break
        pop!(tree[end])
        pop!(path)
        isempty(path) && break
      end
      isempty(tree) && break
    else
      push!(tree, sons)
    end
    step = tree[end][end]
    append!(path, step)
    if path[end] == stop
      push!(paths, copy(path))
      pop!(path)
      pop!(tree[end])
      while isempty(tree[end])
        pop!(tree)
        pop!(path)
        isempty(tree) && break
        pop!(tree[end])
      end
      isempty(tree) && break
      step = tree[end][end]
      append!(path, step)
    end
  end
  return paths
end
path_finding(matrix, point) = path_finding(matrix, point, point)

"""
将各元素按数组顺序记为二进制数
"""
function change(v::Vector)::Int128
  v = sort(v)
  value::Int128 = 0
  for i in v
    value += 1 << (i - 1)
  end
  return value
end
"""
检查两条回路是否一致
"""
function check(a::ClosedLoop, b::ClosedLoop)
  m = length(a.links)
  n = length(b.links)
  m != n && return true
  for j = 1:n
    if b.links[j] == a.links[1]
      if a.links[1:end-1] == [b.links[j:end]; b.links[2:j-1]]
        return false
      else
        return true
      end
    end
  end
  return true
end

"""
生成闭合回路,并进行分类
"""
function circuit_classification(x::SystemMap)
  sum_points = Sum[]
  for k in x.links
    k isa Sum && push!(sum_points, k)
  end
  loop_base = Set([])
  for s in sum_points
    paths = path_finding(x.adjacency_matrix, s.order)
    isempty(paths) && continue
    push!(loop_base, paths...)
  end
  loop = Set{ClosedLoop}([])
  order = 1
  while !isempty(loop_base)
    c = pop!(loop_base)
    isempty(c) && continue
    tf = 1
    for i in eachindex(c)[1:end-1]
      x.links[c[i]] isa Sum && continue
      tf *= x.links[c[i]].tf * x.adjacency_matrix[c[i], c[i+1]]
    end
    if tf isa Number
      tf = Fraction([tf], [1])
    elseif tf isa Polynomial
      tf = Fraction(tf, Polynomial([1]))
    end
    push!(loop, ClosedLoop(change(c[1:end-1]), order, copy(c), tf))
    order += 1
  end
  isempty(loop) && return Dict()
  pre = Dict()
  for i in loop
    isempty(pre) && (push!(pre, [i] => i.value); continue)
    flag = true
    for l in keys(pre)
      flag = check(i, l[1])
      !flag && break
    end
    flag && push!(pre, [i] => i.value)
  end
  tree = Dict(1 => pre)
  order = 2
  while true
    mather = copy(loop)
    new = Dict()
    for (k, v) in tree[order-1]
      delete!(mather, k...)
      for i in mather
        if v & i.value == 0
          push!(new, [k; i] => v | i.value)
        end
      end
    end
    if isempty(new)
      break
    else
      push!(tree, order => new)
      order += 1
    end
  end
  return tree
end

"""
生成方框图特征式
"""
function feature_formula(x::Dict)
  # 梅森公式
  Δ = 1
  for (k, v) in x
    Δ += -1^k * sum(keys(v)) do x
      product = 1
      for i in map((y) -> y.tf, x)
        product *= i
      end
      return product
    end
  end
  return Δ
end

"""
类型收集
"""
function collect_type(x::Vector, y::Type)
  ans = []
  for k in x
    k isa y && push!(ans, k)
  end
  return ans
end

Base.:*() = 1

"""
生成梅森公式的分子,一对IO
"""
function forward_channel(i, o, x::SystemMap, d::Dict)
  ps = path_finding(x.adjacency_matrix, i, o)
  fc = []
  for i in eachindex(ps)
    s = map(eachindex(ps[i][2:end-1])) do t
      x.links[ps[i][t+1]] isa Sum && return 1
      x.links[ps[i][t+1]].tf * x.adjacency_matrix[ps[i][t+1], ps[i][t+2]]
    end
    if length(s) != 1
      tf = *(s...)
    else
      tf = s[1]
    end
    if tf isa Number
      tf = Fraction([tf], [1])
    elseif tf isa Polynomial
      tf = Fraction(tf, Polynomial([1]))
    end
    push!(fc, ForwardChannel(change(ps[i]), i, ps[i], tf))
  end
  gₖ = 0
  for k in fc
    Δₖ = 1
    for (q, p) in d
      z = 0
      for (m, n) in p
        if k.value & n == 0
          t = map((u) -> u.tf, m)
          if length(t) == 1
            z += t[1]
          else
            z += *(t...)
          end
        end
      end
      Δₖ += -1^q * z
    end
    gₖ += k.tf * Δₖ
  end
  return gₖ
end

"""
生成传递矩阵
"""
function transfer_matrix(x::SystemMap)
  input = collect_type(x.links, Input)
  output = collect_type(x.links, Output)
  dict = circuit_classification(x)
  Δ = feature_formula(dict)
  ans = Matrix(undef, length(output), length(input))
  for i in eachindex(input)
    for j in eachindex(output)
      gₖ = forward_channel(input[i].order, output[j].order, x, dict) / Δ
      if gₖ isa Number
        gₖ = Fraction([gₖ], [1])
      elseif gₖ isa Polynomial
        gₖ = Fraction(gₖ, Polynomial([1]))
      end
      ans[j, i] = gₖ
    end
  end
  return ans, map((x) -> x.order, input), map((x) -> x.order, output)
end
