# London Workshop

## Prerequisites

* Shell terminal (use WSL if on Windows)
* Git
* [Devbox](https://www.jetify.com/devbox/docs/installing_devbox)

## Setup

This section describes the manual setup for the workshop. It is recommended to use the Terraform setup as described in the root `README.md`.

### Common

```sh
echo "[default]
aws_access_key_id = $AWS_ACCESS_KEY_ID
aws_secret_access_key = $AWS_SECRET_ACCESS_KEY
" >aws-creds.conf
```

### Hub Cluster

```sh
eksctl create cluster --config-file ${ROOT}/localenv/eksctl.yaml \
    --kubeconfig $KUBECONFIG

kubectl create namespace a-team
```

### Hub Crossplane

```sh
# TODO: Move to Argo CD
kubectl apply --filename ${ROOT}/crossplane-config/config-sql.yaml

# TODO: Move to Argo CD
kubectl apply --filename ${ROOT}/crossplane-config/config-kubernetes.yaml

sleep 60

kubectl wait --for=condition=healthy provider.pkg.crossplane.io \
    --all --timeout=600s
```

### Staging Cluster

```sh    
# TODO: Move to Argo CD
kubectl create ns a-team --dry-run=client -o yaml | kubectl apply --filename -
yq --inplace ".spec.parameters.apps.argocd.repoURL = \"$(git config --get remote.origin.url)\"" \
    examples/crossplane-eks-staging.yaml
kubectl apply --namespace a-team --filename ${ROOT}/examples/crossplane-eks-staging.yaml

# TODO: Remove this command. It's here only to give visibility until it is moved to Argo CD.
./crossplane beta trace clusterclaim staging --namespace a-team

# Wait until all the resources are available

aws eks update-kubeconfig --region us-west-2 \
    --name staging --kubeconfig ${ROOT}/kubeconfig-staging.yaml

INGRESS_IPNAME=$(kubectl --kubeconfig ${ROOT}/kubeconfig-staging.yaml \
    --namespace traefik get service traefik \
    --output jsonpath="{.status.loadBalancer.ingress[0].hostname}")

INGRESS_IP=$(dig +short $INGRESS_IPNAME) 

while [ -z "$INGRESS_IP" ]; do
    sleep 10
    INGRESS_IPNAME=$(kubectl \
        --kubeconfig ${ROOT}/kubeconfig-staging.yaml --namespace traefik \
        get service traefik \
        --output jsonpath="{.status.loadBalancer.ingress[0].hostname}")
    INGRESS_IP=$(dig +short $INGRESS_IPNAME) 
done

INGRESS_IP=$(echo $INGRESS_IP | awk '{print $1;}')

INGRESS_IP_LINES=$(echo $INGRESS_IP | wc -l | tr -d ' ')

if [ $INGRESS_IP_LINES -gt 1 ]; then
    INGRESS_IP=$(echo $INGRESS_IP | head -n 1)
fi

yq --inplace \
    ".spec.parameters.apps.argocd.host = \"argocd.$INGRESS_IP.nip.io\"" \
    examples/crossplane-eks-staging.yaml

export KUBECONFIG=/tmp/hub-cluster

# TODO: Move to Argo CD
kubectl --namespace a-team apply \
    --filename ${ROOT}/examples/crossplane-eks-staging.yaml

echo "http://argocd.$INGRESS_IP.nip.io"

# Open it in a browser
# Use `admin` as the username and `admin123` as the password
```

### Kratix

Verify pre-requisites:
```sh
kubectl wait --namespace cert-manager \
    deployment --selector app=cert-manager \
    --for=condition=Available
kubectl wait --namespace cert-manager \
    deployment --selector app=webhook \
    --for=condition=Available
kubectl wait --namespace cert-manager \
    deployment --selector app=cainjector \
    --for=condition=Available
```

Note: If you need to install Cert Manager you can use the file
`${ROOT}/kratix-config/argoapp-certmanager.yaml`

Install Kratix:
```sh
kubectl apply \
    --filename ${ROOT}/kratix-config/argoapp-kratix.yaml
```

Validate Kratix is healthy:
```sh
kubectl wait --namespace kratix-platform-system \
    deployment --selector app.kubernetes.io/instance=kratix \
    --for=condition=Available
```

## Destroy

```sh
kubectl --kubeconfig ${ROOT}/kubeconfig-staging.yaml \
    --namespace traefik delete service traefik

rm ${ROOT}/staging/*.yaml

git add .

git commit -m "Destroy"

git push

kubectl get managed

# Wait until all the managed resources are removed (ignore `object` resources)

eksctl delete cluster --config-file ${ROOT}/eksctl.yaml
```
