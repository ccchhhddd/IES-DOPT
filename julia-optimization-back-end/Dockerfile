# pull latest julia image
FROM --platform=linux/amd64 julia:1.9.2

# set up the app
RUN mkdir /home/app
COPY . /home/app
WORKDIR /home/app

# instantiate Julia packages
RUN julia -e "ENV[\"JULIA_NUM_PRECOMPILE_TASKS\"]=1;ENV[\"JULIA_PKG_SERVER\"]=\"https://mirrors.pku.edu.cn/julia/\";using Pkg; Pkg.activate(\".\"); Pkg.instantiate(); Pkg.precompile(); "

# ports
EXPOSE 8080

# run app
CMD julia -e "using Pkg; Pkg.activate(\".\");Pkg.instantiate();include(\"main.jl\");" 

