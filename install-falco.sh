#!/bin/bash
dnf -y install make
docker pull falcosecurity/driverkit-builder

GO111MODULE="on" go get github.com/falcosecurity/driverkit

kernelversion=$(uname -v | cut -f1 -d'-' | cut -f2 -d'#')
kernelrelease=$(uname -r)


git clone https://github.com/falcosecurity/driverkit.git
cd driverkit/
mv /root/go/bin/driverkit /usr/bin

#https://computingforgeeks.com/install-docker-and-docker-compose-on-rhel-8-centos-8/


sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum  makecache
sudo yum -y install docker-ce --allowerasing
sudo systemctl enable --now docker
sudo systemctl start  docker


driverkit docker --output-module /tmp/falco.ko --kernelversion=$kernelversion --kernelrelease=$kernelrelease --driverversion=dev --target=centos

sudo dnf -y install podman --allowerasing

sudo cp /tmp/falco.ko /lib/modules/$kernelrelease/falco.ko
sudo depmod
sudo modprobe falco

kubectl create ns falco


kubectl create configmap falco-config --from-file=falco/falco-config -n falco
kubectl apply -f falco/install -n falco

