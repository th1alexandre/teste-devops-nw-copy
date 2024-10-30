#!/bin/bash

## Set variables
# DockerHub
DOCKERHUB_NAMESPACE="th1alexandre"
DOCKERHUB_REPOSITORY="teste-devops-nw"
DOCKERHUB_TAG="latest"

# Docker container
DOCKER_IMAGE="$DOCKERHUB_NAMESPACE/$DOCKERHUB_REPOSITORY:$DOCKERHUB_TAG"
CONTAINER_NAME="teste-devops-nw"

## Docker
# Update package list and install prerequisites
sudo apt-get update
sudo apt-get install -y \
    curl \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    git

# Add Docker's official GPG key:
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install Docker
sudo apt-get install -y \
	docker-ce \
	docker-ce-cli \
	containerd.io \
	docker-buildx-plugin \
	docker-compose-plugin

## Run teste-devops-nw container
sudo docker pull $DOCKER_IMAGE
sudo docker run -d --name $CONTAINER_NAME -p 5000:5000 $DOCKER_IMAGE
