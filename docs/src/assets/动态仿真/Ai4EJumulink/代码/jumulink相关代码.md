```julia
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
```
