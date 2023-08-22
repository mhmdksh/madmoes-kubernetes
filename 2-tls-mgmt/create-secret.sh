/bin/bash

GANDI_API_KEY=""
kubectl create secret generic gandi-credentials --namespace cert-manager --from-literal=api-token='$GANDI_API_KEY'
