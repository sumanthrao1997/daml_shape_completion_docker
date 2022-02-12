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
    build-essential \
    ccache \
    cmake \
    git \
    hdf5-tools \
    libhdf5-serial-dev \
    libreadline-dev \
    # nvidia-cuda-toolkit \
    unzip \
    wget \
    libgtk2.0-dev \
    pkg-config \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    libtbb2 \
    libtbb-dev \
    libjpeg-dev \
    libpng-dev \
    libtiff-dev \
    libjasper-dev \
    libdc1394-22-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Eigen from source
RUN git clone --depth 1 https://gitlab.com/libeigen/eigen.git -b 3.3 \
    && cd eigen \
    && mkdir -p build \
    && cd build \
    && cmake .. && make -j install

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
# install python libs
RUN apt install -y python-pip \
    python-numpy \
    python-h5py \
    cython \
    python-collada \
    python-opencv

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

# install ceres
RUN apt remove cmake -y

# installing latest cmake
RUN wget http://www.cmake.org/files/v3.6/cmake-3.6.0.tar.gz \
    && tar -xvzf cmake-3.6.0.tar.gz \
    && cd cmake-3.6.0 \
    && ./configure \
    && make \
    && make install

# installing gflags need to install thuis
RUN git clone --depth 1 https://github.com/gflags/gflags \
    && cd gflags \
    && mkdir build \
    && cd build \
    && cmake .. \
    && make -j \
    && make install


RUN apt install -y libgoogle-glog-dev \
    libsuitesparse-dev \
    libatlas-base-dev \
    && git clone https://ceres-solver.googlesource.com/ceres-solver

COPY ceres_patch.diff /ceres-solver/

RUN cd ceres-solver \
    && git apply ceres_patch.diff  

RUN mkdir ceres-bin \
    && cd ceres-bin \
    && cmake ../ceres-solver \
    && make -j \
    && make install



