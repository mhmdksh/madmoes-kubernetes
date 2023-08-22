# Ingress & Ingress Controllers:
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
