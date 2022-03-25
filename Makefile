# Done by nacho with love
.PHONY = build run

build:
	nvidia-docker build -t shape_comp . 
run:
	docker run --gpus all --rm -it -v /data:/automount_home_students/snagulavancha/mnt shape_comp:latest /bin/bash