

all : build run

build : 
	@echo "Building docker image : ubuntu:vnc..."
	docker build -t ubuntu:vnc.

run  : 
	@echo "Running docker image : ubuntu:vnc..."
	docker run -it --rm -p 6080:6080 -p 8000:8000 --name ubuntu_vnc ubuntu:vnc
	