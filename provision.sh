#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update

sudo apt-get remove -y docker docker-engine docker.io
sudo apt-get install -y \
     apt-transport-https \
     ca-certificates \
     curl \
     gnupg2 \
     software-properties-common
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/debian \
   $(lsb_release -cs) \
   stable"
sudo apt-get update -y
sudo apt-get install -y --force-yes docker-ce

sudo usermod -aG docker vagrant
sudo service docker start
sudo docker version

sudo adduser --ingroup docker --disabled-password --gecos "" docker
sudo mkdir /home/docker/.ssh
sudo chmod 700 /home/docker/.ssh
sudo chown -R docker:docker /home/docker
