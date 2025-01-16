#!/bin/bash


echo "******installation de l'openJDK Eclipse pour exécution locale"
sudo apt install -y wget apt-transport-https
wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | sudo apt-key add -
echo "deb https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | sudo tee /etc/apt/sources.list.d/adoptium.list
sudo apt update
sudo apt install -y temurin-17-jdk

echo "******installation de Minikube 1.34.0"
OS=linux
MINIKUBE_VERSION=1.34.0
curl -LO https://storage.googleapis.com/minikube/releases/v${MINIKUBE_VERSION}/minikube-${OS}-amd64
sudo install minikube-${OS}-amd64 /usr/local/bin/minikube
rm minikube-${OS}-amd64
echo "******installation de kubectl v1.30.5"
K8S_VERSION=1.30.5
curl -LO https://dl.k8s.io/release/v${K8S_VERSION}/bin/${OS}/amd64/kubectl
sudo install kubectl /usr/local/bin/kubectl
rm kubectl

echo "******installation du gestionnaire homebrew"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo >> /home/cesi/.bashrc
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/cesi/.bashrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
sudo apt install -y build-essential

echo "*******installation de Tilt pour faciliter le déploiement K8s"
brew install tilt-dev/tap/tilt

echo "*******installation d'Helm 3.15.4 compatible K8s v1.30.5"
HELM_VERSION=3.15.4
wget https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz
tar -zxvf helm-v${HELM_VERSION}-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm

echo "******installation HTTPie"
brew install httpie
echo "*******installation de Siege"
sudo apt update -y
sudo apt install siege -y

echo "*******installation de Grype pour les tests de vulnérabilité en local"
brew tap anchore/grype
brew install grype
echo "*******installation de Kubeconform pour valider les manifestes Kubernetes en local"
brew install kubeconform

echo "*******installation de wslview pour ouvrir un nav depuis la distrib WSL"
sudo apt install -y wslu




