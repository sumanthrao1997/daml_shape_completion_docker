# Done by nacho with love
.PHONY = build run

build:
	nvidia-docker build -t shape_comp . 
run:
	docker run --gpus all --rm -it shape_comp:latest

