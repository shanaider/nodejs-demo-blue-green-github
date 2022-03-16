#!/bin/bash
## export env
VERSION=1.21
OS=xUbuntu_20.04

echo $VERSION
echo $OS


## set timezone
timedatectl set-timezone Asia/Bangkok

## disable firewalld
systemctl stop firewalld
systemctl disable firewalld

## disable swapoff
swapoff -a
sed -i "s/\/swap/#\/swap/g" /etc/fstab


# Set up required sysctl params, these persist across reboots.
sudo modprobe overlay
sudo modprobe br_netfilter
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system


## Run
cat <<EOF | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /
EOF
cat <<EOF | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list
deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /
EOF

curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers.gpg add -
curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/Release.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers-cri-o.gpg add -


## install crio
sudo apt-get update
apt-get install cri-o cri-o-runc -y


systemctl daemon-reload
systemctl enable crio
systemctl restart crio

## install crictl
sudo apt install cri-tools -y
sudo crictl info


## edit /etc/crio/crio.conf >> cgroup_manager = "systemd"
sed -i "s/cgroupfs/systemd/g" /etc/crio/crio.conf



## Letting iptables see bridged traffic

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system


##install kubelet kubeadm kubectl
sudo apt-get update && sudo apt-get install -y apt-transport-https curl

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

sudo apt-get update
sudo apt-get install -y kubelet=1.21.2-00 kubeadm=1.21.2-00 kubectl=1.21.2-00
sudo apt-mark hold kubelet kubeadm kubectl


## restart crio
systemctl restart crio