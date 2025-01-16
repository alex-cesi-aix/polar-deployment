Prérequis
---------
--------
* git
* JDK 17 - pour tester en local
* Docker ou si WSL, intégration Docker Desktop
* kubectl et Minikube ou KinD
* Tilt
* Helm
* curl
* (optionnel) Siege et HTTPie
* Si WSL, wslview

pour installer les prérequis (distribution Ubuntu 22.0.4 ou 24.0.4)

```.../polar-deployment$ sh pre_install.sh```

_note : le script installe Minikube mais pas de Docker_


Mise en place de l'infrastructure d'exécution
---------------------------------------------
---------------------------------------------
1. Création d'un cluster cesi 8go ram :

```minikube start --cpus 4 --memory 8g --driver docker --kubernetes-version v1.30.5 --profile cesi```

```minikube addons enable ingress -p cesi```

2. Création du namespace polar :

```kubectl create namespace polar```

3. Assignation du ns polar au contexte courant kubectl :

```kubectl config set-context --current --namespace=polar```

4. installation helm 3.15.4 :

```wget https://get.helm.sh/helm-v3.15.4-linux-amd64.tar.gz```

```tar -zxvf helm-v3.15.4-linux-amd64.tar.gz```

```sudo mv linux-amd64/helm /usr/local/bin/helm```

```rm helm-v3.15.4-linux-amd64.tar.gz```

```rm -rf linux-amd64```

5. installation cert-manager 1.16 dans le namespace cert-manager du cluster cesi :

```helm repo add jetstack https://charts.jetstack.io```

```helm install cert-manager jetstack/cert-manager --create-namespace --namespace cert-manager --version v1.16 --set crds.enabled=true --wait```

6. installation istio 1.24.1 :

**Installation du CLI**

```ISTIO_VERSION=1.24.1```

```curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${ISTIO_VERSION} TARGET_ARCH=x86_64 sh -```

```sudo install istio-${ISTIO_VERSION}/bin/istioctl /usr/local/bin/istioctl```

```rm -r istio-${ISTIO_VERSION}```

```istioctl version --remote=false```

**Installation d'Istio dans le namespace istio-system**

```istioctl experimental precheck```

```istioctl install --skip-confirmation --set profile=demo --set meshConfig.accessLogFile=/dev/stdout --set meshConfig.accessLogEncoding=JSON```

7. Installatation des services complémentaires Istio pour l'observation du trafic (Kiali) et le tracing (Jaeger) :

```kubectl apply -n istio-system -f https://raw.githubusercontent.com/istio/istio/${ISTIO_VERSION}/samples/addons/kiali.yaml```

```kubectl apply -n istio-system -f https://raw.githubusercontent.com/istio/istio/${ISTIO_VERSION}/samples/addons/jaeger.yaml```

```kubectl apply -n istio-system -f https://raw.githubusercontent.com/istio/istio/${ISTIO_VERSION}/samples/addons/prometheus.yaml```

_note : prometheus doit être déployé pour la collecte des métriques notamment pour l'affichage du graphe Kiali_

8. Configuration de l'injection auto des sidecars dans les pods du namespace polar :

```kubectl label namespace polar istio-injection=enabled --overwrite```

**Verif de la labellisation**

```kubectl get namespace -L istio-injection```

Déploiement
-----------
-----------
1. Déclaration du ns par défaut (si non déclaré en amont ou minikube redémarré):

```kubectl config set-context --current --namespace=polar```

2. Déploiement des services de données dans le ns polar :

```.../polar-deployment/k8s/platform/development$ kubectl apply -f services```

3. Ajout dans /etc/hosts de la ligne :

```127.0.0.1	polarbookshop.io	kiali.polarbookshop.io	tracing.polarbookshop.io```

4. Installation du provider référençant Jaeger :

```.../polar-deployment/k8s/platform/development$ istioctl install -f config-istio-tracing/tracing.yaml --skip-confirmation```

5. déploiement, dans le ns istio-system de 
* (cert-manager) la config de l'issuer, des certificats
* (istio) de l'activation du traçage, des configs Istio d'accès à Kiali et Jager :

```.../polar-deployment/k8s/platform/development$ kubectl apply -f istio-system -n istio-system```

_note: Pour afficher les infos d'une Istio Ingress Gateway :  ```kubectl get deployment -n istio-system istio-ingressgateway -o yaml```_

6. Démarrer un tunnel minikube pour le profil cesi :

```minikube tunnel -p cesi```

_note : si le le profil n'est pas celui par défaut l'option -p est nécessaire_

7. Déploiement de l'application :

```.../polar-deployment$ tilt up```

_note : les images des containers sont construites avec BuildPack intégré à Spring Boot_

Tests de l'application
----------------------
---------------------
**test par exécution de 100 requêtes :**

```for i in $(seq 1 100); do curl -s -o /dev/null "https://polarbookshop.io/books"; done```

**test avec Siege :**

```siege https://polarbookshop.io/books -c1 -d1 -v```


**Observation du trafic dans l'UI Kiali:**

```wslview https://kiali.polarbookshop.io```

**Observation des traces dans l'UI Jaeger :**

```wslview https://tracing.polarbookshop.io```

# alternative avec script

1. lancement du script de mise en place de l'infra :
```.../polar-deployment$ sh install_infra.sh```

_note : l'installation d'istioctl est commentée - à décommenter pour installer_

2. Déploiement des services de données dans le ns polar :

```.../polar-deployment/k8s/platform/development$ kubectl apply -f services```

3. installation du provider référençant Jaeger :

```.../polar-deployment/k8s/platform/development$ istioctl install -f config-istio-tracing/tracing.yaml --skip-confirmation```

4. Déploiement, dans le ns istio-system des manifestes configurant la sécurité https et le service mesh

```.../polar-deployment/k8s/platform/development$ kubectl apply -f istio-system -n istio-system```

5. Démarrer un tunnel minikube pour le profil cesi :

```minikube tunnel -p cesi```

_note : si le le profil n'est pas celui par défaut l'option -p est nécessaire_

6. Déploiement de l'application :

```.../polar-deployment$ tilt up```

**test de l'application -cf. plus haut**

GitHub Actions 
-------------
-------------
=> les workflow sont déclenchés au push de chaque dépôt (excepté polar-deployment non associé à un workflow)

Remplacer alex-cesi-aix par le nom du compte GitHub dans les fichiers .github/workflows/commit-stage.yml

Publication d'image dans Github Container Registry
--------------------------------------------------
--------------------------------------------------

Créer un jeton de sécurité (personal access token) :

_Compte GitHub > Settings > Developer Settings > Personal access tokens > Generate new token (classic)_

* Note = nom du jeton (ex : local-dev-environment)
* Cocher repo
* Cocher workflow
* Cocher write:packages
* cliquer sur Generate token

Sources
-------
-------
basé sur les codes sources des livres :
* Cloud Native Spring in Action With Spring Boot and Kubernetes
  * Thomas Vitale
  * Manning
  

* Hands-On Microservices with Spring Boot and Spring Cloud: Build and deploy Java microservices using Spring Cloud, Istio, and Kubernetes
  * Magnus Larsson
  * Packt













