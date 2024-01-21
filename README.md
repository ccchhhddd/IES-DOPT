# 综合能源优化控制仿真平台开发项目

## 本项目所使用使用前端框架

[![license](https://img.shields.io/badge/license-MIT-green.svg)](./LICENSE)

- [Soybean Admin](https://github.com/honghuangdc/soybean-admin) 是一个基于 Vue3、Vite3、TypeScript、NaiveUI、Pinia 和 UnoCSS 的清新优雅的中后台模版，它使用了最新流行的前端技术栈，内置丰富的主题配置，有着极高的代码规范，基于文件的路由系统以及基于 Mock 的动态权限路由，开箱即用的中后台前端解决方案，也可用于学习参考。

## 部署服务器

### 前端部署

1.对项目文件进行本地打包生成dist文件夹
```
npm run build
```
2.执行命令运行Dockerfile文件，对采用ngnix服务的前端项目进行docker镜像封装
```
docker build -t front_end -f .\docker\Dockerfile .
```
3.对生成的docker镜像进行改名操作(dockerhub用户名/镜像名)
```
docker tag front_end chenghd/front_end
```
4.将镜像push到远端dockerhub仓库
```
docker push chenghd/front_end
```
5.在服务器端拉取远端镜像
```
docker pull chenghd/front_end
```
6.在服务器端运行docker镜像生成docker容器
```
docker run --name front -p 80:80 -d chenghd/front_end
```

### 后端部署(探索中)
```
using PackageCompiler
```
```
create_app("julia-simulation-back-end", "backendCompiled", force=true, incremental=true)
```
```
docker build -t backend .
```

## 使用说明(本地开发者模式)

### 先将项目克隆到本地
#### 方法一：使用GitKraken进行项目克隆及项目相关操作（推荐）
GitKraken使用详情请见 https://ai4energy.github.io/Ai4EDocs/dev/WorkFlow/gitworkflow/

如果你是学生可以使用学校的邮箱注册，学生包有gitkraken的会员 https://education.github.com/pack

#### 方法二：git命令行手动操作
首先创建一个空的文件夹用于存放项目，在创建的文件夹中 右键选择 Git Bash Here
输入

```
git init
```

```
git clone https://github.com/ccchhhddd/IES-DOPT.git
```

如果克隆过程存在问题参考这篇文章进行解决
https://blog.csdn.net/m0_63230155/article/details/132070860

### 前端

前端需要下载 node.js 使用 npm 库安装相关库以及运行相关代码

```
npm install ——————配置环境以及安装相关包（在IES-DOPT文件下的环境运行即可）
```

```
npm run dev ——————运行程序
```

### 后端

初次运行时间会略长，请耐心等待

```
直接运行main.jl文件即可 文件路径：  /julia-simulation-back-end/main.jl
```

初次进行仿真运算时间会略长，请耐心等待



