# Kubernetes
## Cluster Setup & Prerequisites:
###### 1. Deploy Digital Ocean Kubernetes Cluster Using Control Panel
See: https://docs.digitalocean.com/products/kubernetes/how-to/create-clusters/
###### 2. Install kubernetes tools on your machine

* kubectl (Latest Version): Tool to manage kubernetes clusters (Remotely and Locally)
    * See https://kubernetes.io/docs/tasks/tools/
* helm (Latest version): A package manager for Kubernetes, that will seemlessly deploy kubernetes components from helm charts (configs that 
contain the info for the different components)
    * See https://helm.sh/docs/intro/install/

###### 3. Configure kubectl to point to the Cluster:	
```
See: https://docs.digitalocean.com/products/kubernetes/how-to/connect-to-cluster/ 
```
###### 4. Access Cluster and verify it is working fine:
```
kubectl cluster-info
```
###### 5. Deploy a new storage class for our Volumes [Important]
```
kubectl apply -f common/storage-class-retain.yaml
```
## Ingress & Ingress Controllers:
The ingress is like a gateway to our apps deployed in our kubernetes cluster. By default, when it is deployed, it will create a public IP 
Address that will make our apps internet accessable.
By Default, the lifespan of the public IP address created by the ingress controller will end when the ingress controller is dead, or deleted. 
So for that we will create a static IP Address and attached it to our Ingress Controller upon creation.

###### 1. Add the Helm Repository for nginx-ingress controller
```
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add  stable https://charts.helm.sh/stable
helm repo update
```
###### 2. Install the Ingress controller with Helm
```
helm install ingress-nginx ingress-nginx/ingress-nginx --create-namespace \
--namespace ingress-nginx \
--set controller.replicaCount=3 \
--set controller.nodeSelector."kubernetes\.io/os"=linux \
--set defaultBackend.nodeSelector."kubernetes\.io/os"=linux \
--set controller.service.externalTrafficPolicy=Local
```
###### 3. Patch the Ingress Service to be able with some extra loadbalancer configs
####### For Proxy & Backend Alive Settings
```
kubectl -n ingress-nginx annotate service ingress-nginx-controller service.beta.kubernetes.io/do-loadbalancer-enable-proxy-protocol="true"
kubectl -n ingress-nginx annotate service ingress-nginx-controller service.beta.kubernetes.io/do-loadbalancer-enable-backend-keepalive="true"
```
####### For Load Balancer Size
```
kubectl -n ingress-nginx annotate service ingress-nginx-controller service.beta.kubernetes.io/do-loadbalancer-size-unit="2"
kubectl -n ingress-nginx annotate service ingress-nginx-controller 
service.beta.kubernetes.io/do-loadbalancer-disable-lets-encrypt-dns-records="false"
```
###### 4. Deploy the custom Ingress Configmap
```
kubectl apply -f common/ingress-configmap.yaml
```
## TLS Certificate Management on Kubernetes
The below will walk you through the steps to get the TLS Certificates working with the Kubernetes Ingress:  
**NOTE:**
 Since we are currently using Gandi to host our domain, some of these steps are specific for certificate issuence and domain verification for 
Domains hosted on Gandi
###### 1. Add the Certbot Repo and update the repo cache
```
helm repo add jetstack https://charts.jetstack.io
helm repo update
```
###### 2. Apply CRDs
```
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.12.3/cert-manager.crds.yaml
```
###### 3. Install the certificate manager
```
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.9.1 --set 
'extraArgs={--dns01-recursive-nameservers=8.8.8.8:53\,1.1.1.1:53}'
```
###### 4. Create the secret to Gandi API For Adding records
**NOTE:** Refer to this link https://yunohost.org/en/providers/registrar/gandi/autodns for generating the <Gandi API Key> for your 
subscription
```
kubectl create secret generic gandi-credentials --namespace cert-manager --from-literal=api-token='<Gandi API Key>'
```
###### 5. Install the Gandi Webhook for verification
```
helm install cert-manager-webhook-gandi --repo https://bwolf.github.io/cert-manager-webhook-gandi --version v0.2.0 --namespace cert-manager 
--set features.apiPriorityAndFairness=true --set logLevel=2 --generate-name
```
###### 6. Create the Cluster Issuer
```
kubectl apply -f common/cert-manager-TLS-staging-issuer.yaml
```
###### 7. Generate a Wildcard Certificate with the Cluster Issuer
```
kubectl apply -f common/wildcard-certificate.yaml
```
###### 8. Check if your certificate is ready
```
kubectl get certificate
```
## Deploying our apps on Kubernetes
##### 1. Create our app namespaces
```
kubectl apply -f common/namespaces.yaml
```
##### 2. Create our redis cluster deployment for our apps using helm charts
```
helm install redis-backend bitnami/redis \
--namespace backend \
--set serviceAccount.create="true" \
--set serviceAccount.name="auth" \
--set architecture="standalone" \
--set auth.enabled="false" \
--set master.kind="Deployment"
```
##### 3. Fastly deploy our apps on the cluster
###### For authentication microservice
```
cd auth/
kubectl apply -f auth-configMap.yaml,auth-pvc.yaml,auth-deployment.yaml
```
###### For impact-graph microservice
```
cd impact-graph/
kubectl apply -f ig-configMap.yaml,ig-pvc.yaml,ig-deployment.yaml,ig-service.yaml
```
###### For notification-center microservice
```
cd notification-center/
kubectl apply -f nc-configMap.yaml,nc-pvc.yaml,nc-deployment.yaml,nc-service.yaml
```
###### For apigiv microservice
```
cd apigiv/
kubectl apply -f api-configMap.yaml,api-pvc.yaml,api-deployment.yaml,api-service.yaml
```
**Note:** Alternativley you can deploy the components one by one in order to better keep track of how they are being setup (We are deploying 
out authenitcation microservice as an example)

###### Check and Deploy the configuration map in auth/auth-configMap.yaml:
```
kubectl apply -f auth/auth-configMap.yaml
kubectl get configmaps -n auth
```
###### Check and Deploy the Persistent volume and Persistent volume claim using the storage class that we created earlier
```
kubectl apply -f auth/auth-pvc.yaml
kubectl get pv,pvc -n auth
```
###### Check and Deploy the authentication deployment and service
```
kubectl apply -f auth/auth-deployment.yaml
kubectl get deploy -n auth
```
###### Check and Deploy the authentication service
```
kubectl apply -f auth/auth-service.yaml
kubectl get service -n auth
```
##### 4. Finalize the deployment and make it accessable to the outside world:
###### Apply the Network Policies:
```
kubectl apply -f common/network-policy-backend.yaml
```
###### Apply the Ingress:
```
kubectl apply -f common/ingress.yaml
```
##### Verify that your apps are working properly and reachable at the below links:
* **impact-graph**: https://impact-graph.staging.k8s.giveth.io/
* **apiGiv**: https://api.staging.k8s.giveth.io/
* **authentication**: https://auth.staging.k8s.giveth.io/
* **notification-center**: https://notification-center.staging.k8s.giveth.io/
