# Daml_shape_completion docker image

A docker image to run [Daml Shape Completion](https://github.com/davidstutz/daml-shape-completion) using ubuntu 14.04 as base image with cuda.
the docker file builds all the dependencies and the repository. 

Building this container is straightforward using provided Makefile: ```make``` and ```make run```.
To visualise data use ```make debug```, which mounts a /tempdata folder inside the docker image to /mount folder on the host machine. copy the data to /tempdata inside the docker image and visualise on your host machine.

## Credits
I want to thank [Ignacio Vizzo](https://github.com/nachovizzo) and [Federico Magistri](https://github.com/magistri) for helping me in building the dockeer file.
