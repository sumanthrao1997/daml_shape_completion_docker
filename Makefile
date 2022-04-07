# Done by nacho with love
.PHONY = build run debug

build:
	nvidia-docker build -t shape_comp . 
run:
	docker run --gpus all --rm -it shape_comp:latest
debug:
	docker run --gpus all --rm -it --privileged \
	-v /mount:/vizdata \
 	shape_comp:latest 
