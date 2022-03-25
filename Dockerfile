FROM nvidia/cuda:8.0-devel-ubuntu14.04
LABEL maintainer="Sumanth Nagulavancha <s7sunagu@uni-bonn.de>"

# setup environment
ENV TERM xterm
ENV DEBIAN_FRONTEND=noninteractive

# Remove non-working NVIDIA repositories
RUN rm /etc/apt/sources.list.d/cuda.list

# Install essentials
RUN apt-get update && apt-get install --no-install-recommends -y \
    build-essential \
    ccache \
    cmake \
    cython \
    git \
    hdf5-tools \
    pkg-config \
    unzip \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install 3rdparty libraries
RUN apt-get update && apt-get install --no-install-recommends -y \
    libatlas-base-dev \
    libavcodec-dev \
    libavformat-dev \
    libavutil-dev \
    libboost-all-dev \
    libdc1394-22-dev \
    libdouble-conversion-dev \
    libexpat1-dev \
    libfontconfig-dev \
    libfreetype6-dev \
    libgdal-dev \
    libglew-dev \
    libgoogle-glog-dev \
    libgtk2.0-dev \
    libhdf5-serial-dev \
    libjasper-dev \
    libjpeg-dev \
    libjsoncpp-dev \
    liblz4-dev \
    liblzma-dev \
    libnetcdf-dev  \
    libogg-dev \
    libpng-dev \
    libqt5opengl5-dev \
    libqt5x11extras5-dev \
    libreadline-dev \
    libsqlite3-dev \
    libsuitesparse-dev \
    libswscale-dev \
    libtbb-dev \
    libtbb2 \
    libtheora-dev \
    libtiff-dev \
    libtiff-dev \
    libxml2-dev \
    libxt-dev \
    qtbase5-dev \
    qttools5-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Install lua
RUN mkdir lua_build \
    && cd lua_build \
    && wget --no-check-certificate  http://www.lua.org/ftp/lua-5.3.4.tar.gz \
    && tar -zxf lua-5.3.4.tar.gz \
    && cd lua-5.3.4 \
    && make linux test \
    && make install

# Install luarocks
RUN wget --no-check-certificate https://luarocks.org/releases/luarocks-3.8.0.tar.gz \
    && tar zxpf luarocks-3.8.0.tar.gz \
    && cd luarocks-3.8.0 \
    && ./configure && make && make install \
    && luarocks install luasocket

# Install torch distro
RUN git clone --depth 1 https://github.com/torch/distro.git \
    && cd distro \
    && bash install-deps \
    && ./install.sh \
    && ./update.sh \
    && rm -rf /distro

# installing additional python dependencies
RUN apt-get update && apt-get install --no-install-recommends -y \
    python-collada \
    python-dev \
    python-h5py \
    python-numpy \
    python-opencv \
    && rm -rf /var/lib/apt/lists/*

# installing totem with edited rockspec file for git+https
COPY totem-0-0.rockspec /
RUN  . /distro/install/bin/torch-activate && luarocks install totem-0-0.rockspec

#install torch -hd5
RUN . /distro/install/bin/torch-activate && git clone --depth 1 https://github.com/deepmind/torch-hdf5 \
    && cd torch-hdf5 \
    && luarocks make hdf5-0-0.rockspec \
    && rm -rf /torch-hdf5

# installing volumetric lua deps
RUN cd distro \
    && git clone https://github.com/davidstutz/torch-volumetric-nnup.git \
    && git clone https://github.com/clementfarabet/lua---nnx.git \ 
    && cp ./torch-volumetric-nnup/VolumetricUpSamplingNearest.lua ./lua---nnx/ \
    && cp ./torch-volumetric-nnup/generic/VolumetricUpSamplingNearest.c ./lua---nnx/generic/ \  
    && git clone https://github.com/nicholas-leonard/cunnx.git \
    && cp ./torch-volumetric-nnup/cuda/VolumetricUpSamplingNearest.cu ./cunnx/ 

# installing lua--nnx
COPY patch_nnx.diff /distro/lua---nnx/
RUN . /distro/install/bin/torch-activate && cd /distro/lua---nnx \ 
    && git apply patch_nnx.diff \
    && luarocks make nnx-0.1-1.rockspec

# installing cunnx
COPY patch_cunnx.diff /distro/cunnx/
RUN . /distro/install/bin/torch-activate && cd /distro/cunnx/ \
    && git apply patch_cunnx.diff \
    && luarocks make rocks/cunnx-scm-1.rockspec

# install opencv
RUN git clone --depth 1 -b 2.4 https://github.com/opencv/opencv.git \
    && cd opencv \
    && mkdir build \
    && cd build \
    && cmake -D CMAKE_BUILD_TYPE=Release -D CMAKE_INSTALL_PREFIX=/usr/local .. \
    && make -j \
    && make install \
    && rm -rf /opencv

#install vtk from source
RUN wget https://www.vtk.org/files/release/7.1/VTK-7.1.1.tar.gz --no-check-certificate \
    && tar -xzvf VTK-7.1.1.tar.gz && cd VTK-7.1.1 \ 
    && mkdir build && cd build && cmake .. \
    && make -j$(nproc --all) && make install

# installing  cmake3.6 for installing eigen 3.3
RUN wget http://www.cmake.org/files/v3.6/cmake-3.6.0.tar.gz \
    && tar -xvzf cmake-3.6.0.tar.gz \
    && cd cmake-3.6.0 \
    && ./configure \
    && make \
    && make install

# Install Eigen from source
RUN rm -rf /eigen && git clone --depth 1 https://gitlab.com/libeigen/eigen.git -b 3.3.9 \
    && cd eigen \
    && mkdir -p build \
    && cd build \
    && cmake .. && make -j install

# installing gflags need to install this
RUN git clone --depth 1 https://github.com/gflags/gflags \
    && cd gflags \
    && mkdir build \
    && cd build \
    && cmake .. \
    && make -j \
    && make install \
    && rm -rf /gflags

# installing Ceres-Solver
RUN git clone --depth 1 https://ceres-solver.googlesource.com/ceres-solver -b 1.14.0 \
    && mkdir ceres-bin \
    && cd ceres-bin \
    && cmake ../ceres-solver \
    && make -j \
    && make install \
    && rm -rf /ceres-solver

# installing PyMcubes
RUN git clone --depth 1 --branch voxel_centers https://github.com/davidstutz/PyMCubes.git \
    && cd PyMCubes \
    && python setup.py build \
    && python setup.py install \
    && rm -rf /PyMCubes

# Now finally try to build the daml shape completion
RUN git clone --depth 1 https://github.com/davidstutz/daml-shape-completion.git
# installing ,missing lua requirements (only json was missing when checked inside docker)
COPY json-1.0-0.rockspec /
RUN . /distro/install/bin/torch-activate  && luarocks install json-1.0-0.rockspec

# Patch to remove uncessary linking
COPY engelmann.diff /daml-shape-completion/
RUN cd daml-shape-completion && git apply engelmann.diff

#install openblas
RUN wget -O openblas-v0.2.20.zip http://github.com/xianyi/OpenBLAS/archive/v0.2.20.zip \
    && unzip openblas-v0.2.20.zip \
    && cd OpenBLAS-0.2.20 \
    && mkdir build \
    && cd build \
    && cmake .. \
    && make -j \
    && make install

# install suitesparse
RUN ldconfig \
    && wget http://faculty.cse.tamu.edu/davis/SuiteSparse/SuiteSparse-4.5.6.tar.gz \
    && tar -xvzf SuiteSparse-4.5.6.tar.gz \
    && cd SuiteSparse \
    && CUDA_PATH_='which nvcc 2>/dev/null | sed "s/\/bin\/nvcc//"' \
    && make -j \
    && make install

# building shape priors in engelmann directories
RUN cd daml-shape-completion/engelmann/external/viz \
    && mkdir build \
    && cd build \
    && cmake .. \
    && make -j \
    && make install

# # Patch in cmake_modules and CMakeLists to include csparse lib
COPY engelmanncmake.diff /daml-shape-completion/
RUN cd daml-shape-completion && git apply engelmanncmake.diff

# now come back and install the engelmann library
RUN cd daml-shape-completion/engelmann \
    && mkdir build \
    && cd build \
    && pwd \
    && cmake .. \
    && cmake .. \
    && make -j

# building mesh-evaluation
RUN cd daml-shape-completion/ \
    && git clone https://github.com/davidstutz/mesh-evaluation.git \
    && cd mesh-evaluation \
    && mkdir build \
    && cd build \
    && cmake .. \
    && make -j

# building shape priors
RUN cd daml-shape-completion/ && git clone https://github.com/VisualComputingInstitute/ShapePriors_GCPR16.git

# patch for correcting eigen in viz.h and cuda runtime environment off
COPY shapeprior.diff /daml-shape-completion/ShapePriors_GCPR16/

# # first build viz
RUN cd daml-shape-completion/ShapePriors_GCPR16/ \
    && git apply shapeprior.diff \ 
    && cd external/viz \
    && mkdir build \
    && cd build \
    && cmake .. \
    && cmake .. \
    && make -j \
    && make install

# build shape priors
RUN cd daml-shape-completion/ShapePriors_GCPR16/ \
    && mkdir build \
    && cd build \
    && cmake ..\
    && cmake .. -DCMAKE_BUILD_TYPE=Release \
    && make -j

# --------------------------- FOR DEBUGGING, REMOVE LATER ------------------------------------ #
# finally testing on data
# downloading sn clean data
RUN mkdir data  && cd data \
    && wget https://datasets.d2.mpi-inf.mpg.de/cvpr2018-shape-completion/cvpr2018_shape_completion_clean.zip \
    && unzip cvpr2018_shape_completion_clean.zip 

# installing a text editor
RUN apt update && apt install vim -y
# edit the daml-shaape-completion/vae/clean.json file to train as required
