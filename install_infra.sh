#!/bin/bash

echo "******installation du cluster cesi"
minikube start --cpus 4 --memory 8g --driver docker --kubernetes-version v1.30.5 --profile cesi
echo "******installation du contrôleur Ingress"
minikube addons enable ingress -p cesi
echo "création du namespace polar"
kubectl create namespace polar
echo "******désignation du ns polar comme ns par défaut"
kubectl config set-context --current --namespace=polar

echo "******installation cert-manager 1.16 dans le namespace cert-manager du cluster cesi"
helm repo add jetstack https://charts.jetstack.io
helm install cert-manager jetstack/cert-manager --create-namespace --namespace cert-manager --version v1.16 --set crds.enabled=true --wait
echo "******installation istio 1.24.1"
ISTIO_VERSION=1.24.1
#client Istio
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${ISTIO_VERSION} TARGET_ARCH=x86_64 sh -
sudo install istio-${ISTIO_VERSION}/bin/istioctl /usr/local/bin/istioctl
rm -r istio-${ISTIO_VERSION}
rm *.tar.gz
istioctl version --remote=false
istioctl experimental precheck
istioctl install --skip-confirmation --set profile=demo --set meshConfig.accessLogFile=/dev/stdout --set meshConfig.accessLogEncoding=JSON #--set values.pilot.env.PILOT_JWT_PUB_KEY_REFRESH_INTERVAL=15s

echo "******installation des services istio d'observabilité dans le ns istio-system"
kubectl apply -n istio-system -f https://raw.githubusercontent.com/istio/istio/${ISTIO_VERSION}/samples/addons/kiali.yaml
kubectl apply -n istio-system -f https://raw.githubusercontent.com/istio/istio/${ISTIO_VERSION}/samples/addons/jaeger.yaml
kubectl apply -n istio-system -f https://raw.githubusercontent.com/istio/istio/${ISTIO_VERSION}/samples/addons/prometheus.yaml

echo "******configuration l'injection automatique des sidecars dans les pods du namespace polar"
kubectl label namespace polar istio-injection=enabled --overwrite
echo "******affichage de la labellisation"
kubectl get namespace -L istio-injection

echo "******ajout de la resolution de noms hôtes *.polarbookshop.io dans /etc/hosts"
echo "127.0.0.1	polarbookshop.io	kiali.polarbookshop.io	tracing.polarbookshop.io" | sudo tee -a /etc/hosts
