# FROM nvidia/cuda:10.1-base-ubuntu14.04
# FROM nvidia/cuda:8.0-cudnn7-devel-ubuntu14.04
FROM nvidia/cuda:8.0-devel-ubuntu14.04

# setup environment
ENV TERM xterm
ENV DEBIAN_FRONTEND=noninteractive

# Fuck NVIDIA
RUN rm /etc/apt/sources.list.d/cuda.list

# Install essentials
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
    # nvidia-cuda-toolkit \
    build-essential \
    ccache \
    cmake \
    cython \
    git \
    hdf5-tools \
    libatlas-base-dev \
    libavcodec-dev \
    libavformat-dev \
    libavutil-dev \
    libboost-dev \
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
    pkg-config \
    python-collada \
    python-h5py \
    python-numpy \
    python-opencv \
    qtbase5-dev \
    qttools5-dev \
    unzip \
    wget \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# installing latest cmake
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

# installing gflags need to install thuis
RUN git clone --depth 1 https://github.com/gflags/gflags \
    && cd gflags \
    && mkdir build \
    && cd build \
    && cmake .. \
    && make -j \
    && make install

# Ceres
RUN git clone https://ceres-solver.googlesource.com/ceres-solver -b 1.14.0 \
    && mkdir ceres-bin \
    && cd ceres-bin \
    && cmake ../ceres-solver \
    && make -j \
    && make install

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
RUN git clone https://github.com/torch/distro.git && cd distro && bash install-deps &&  ./install.sh && ./update.sh

#install torch -hd5
RUN . /distro/install/bin/torch-activate && git clone --depth 1 https://github.com/deepmind/torch-hdf5 \
    && cd torch-hdf5 \
    && luarocks make hdf5-0-0.rockspec 

# # installing volumetric lua deps
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

RUN git clone --branch voxel_centers https://github.com/davidstutz/PyMCubes.git \
    && cd PyMCubes \
    && python setup.py build \
    && python setup.py install

# install opencv
RUN git clone --depth 1 -b 2.4 https://github.com/opencv/opencv.git \
    && cd opencv \
    && mkdir build \
    && cd build \
    && cmake -D CMAKE_BUILD_TYPE=Release -D CMAKE_INSTALL_PREFIX=/usr/local .. \
    && make -j \
    && make install

#install vtk from source
RUN wget https://www.vtk.org/files/release/7.1/VTK-7.1.1.tar.gz --no-check-certificate \
    && tar -xzvf VTK-7.1.1.tar.gz && cd VTK-7.1.1 \ 
    && mkdir build && cd build && cmake .. \
    && make -j$(nproc --all) && make install

# Now finally try to build the ugliest shit ever
RUN git clone --depth 1 https://github.com/davidstutz/daml-shape-completion.git \
    && cd daml-shape-completion && ls
