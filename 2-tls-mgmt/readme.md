# TLS with Nginx Ingress & Gandi DNS
## Certificate Management
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
kubectl apply -f cert-manager-TLS-staging-issuer.yaml
```
###### 7. Generate a Wildcard Certificate with the Cluster Issuer
```
kubectl apply -f wildcard-certificate.yaml
```
###### 8. Check if your certificate is ready
```
kubectl get certificate
```
