# London Workshop

## Prerequisites

* Shell terminal (use WSL if on Windows)
* Git
* [Devbox](https://www.jetify.com/devbox/docs/installing_devbox)

## Setup

This section should be executed before the workshop in each of attendees accounts.

### Common

```sh
git clone https://github.com/vfarcic/london-2024

cd london-2024

devbox shell

# Replace `[...]` with the AWS Access Key ID
export AWS_ACCESS_KEY_ID=[...]

# Replace `[...]` with the AWS Secret Access Key
export AWS_SECRET_ACCESS_KEY=[...]

echo "[default]
aws_access_key_id = $AWS_ACCESS_KEY_ID
aws_secret_access_key = $AWS_SECRET_ACCESS_KEY
" >aws-creds.conf

export KUBECONFIG=$PWD/kubeconfig-hub.yaml
```

### Hub Cluster

```sh
eksctl create cluster --config-file eksctl.yaml \
    --kubeconfig $KUBECONFIG

kubectl create namespace a-team
```

### Hub Crossplane

```sh
# TODO: Move to Argo CD
helm upgrade --install crossplane crossplane \
    --repo https://charts.crossplane.io/stable \
    --namespace crossplane-system --create-namespace --wait

# TODO: Move to Argo CD
kubectl apply \
    --filename crossplane-config/provider-kubernetes-incluster.yaml

# TODO: Move to Argo CD
kubectl apply \
    --filename crossplane-config/provider-helm-incluster.yaml

# TODO: Move to Argo CD
kubectl apply --filename crossplane-config/config-sql.yaml

# TODO: Move to Argo CD
kubectl apply --filename crossplane-config/config-kubernetes.yaml

sleep 60

kubectl wait --for=condition=healthy provider.pkg.crossplane.io \
    --all --timeout=600s

# TODO: Move to Argo CD
kubectl --namespace crossplane-system \
    create secret generic aws-creds \
    --from-file creds=./aws-creds.conf

# TODO: Move to Argo CD
kubectl apply \
    --filename crossplane-config/provider-config-aws.yaml

yq --inplace \
    ".spec.parameters.apps.argocd.repoURL = \"$(git config --get remote.origin.url)\"" \
    examples/crossplane-eks-staging.yaml

yq --inplace \
    ".spec.parameters.apps.argocd.repoURL = \"$(git config --get remote.origin.url)\"" \
    examples/crossplane-eks-production.yaml
```

### Staging Cluster

```sh    
# TODO: Move to Argo CD
kubectl --namespace a-team apply \
    --filename examples/crossplane-eks-staging.yaml

# TODO: Remove this command. It's here only to give visibility until it is moved to Argo CD.
crossplane beta trace clusterclaim staging --namespace a-team

# Wait until all the resources are available

aws eks update-kubeconfig --region us-east-1 \
    --name staging --kubeconfig $KUBECONFIG

INGRESS_IPNAME=$(kubectl --kubeconfig kubeconfig-staging.yaml \
    --namespace traefik get service traefik \
    --output jsonpath="{.status.loadBalancer.ingress[0].hostname}")

INGRESS_IP=$(dig +short $INGRESS_IPNAME) 

while [ -z "$INGRESS_IP" ]; do
    sleep 10
    INGRESS_IPNAME=$(kubectl \
        --kubeconfig kubeconfig-staging.yaml --namespace traefik \
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

export KUBECONFIG=$PWD/kubeconfig-hub.yaml

# TODO: Move to Argo CD
kubectl --namespace a-team apply \
    --filename examples/crossplane-eks-staging.yaml

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
`kratix-config/argoapp-certmanager.yaml`

Assuming we are installing via ArgoCD applications:
```sh
kubectl apply \
    --filename kratix-config/argoapp-kratix.yaml
```

Validate Kratix is healthy:
```sh
kubectl wait --namespace kratix-platform-system \
    deployment --selector app.kubernetes.io/instance=kratix \
    --for=condition=Available
```

### Backstage

TODO:

### Argo CD

TODO:

## Workshop

Workshop starts here.

### Crossplane

```sh
kubectl get pkg

kubectl get crds | grep aws

cat examples/crossplane-vm.yaml

kubectl apply --filename examples/crossplane-vm.yaml

kubectl get managed

echo "https://marketplace.upbound.io/providers/upbound/provider-aws-ec2"
```

* Open the URL in a browser

```sh
echo "https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1"
```

* Open the URL in a browser

```sh
kubectl apply --filename examples/crossplane-vm.yaml
```

* Stop the VM
* Observe that it started again

```sh
kubectl delete --filename examples/crossplane-vm.yaml

cat examples/crossplane-eks-production.yaml

echo "https://marketplace.upbound.io/configurations/devops-toolkit/dot-kubernetes"
```

* Open the URL in a browser

```sh
cat examples/app.yaml

kubectl --namespace a-team apply --filename examples/app.yaml

kubectl --namespace a-team get all,sqlclaims

crossplane beta trace sqlclaim silly-demo --namespace a-team
```

* We should not `apply` resources directly. We should use Argo CD, hence let's delete everything and start over.

```sh
kubectl --namespace a-team delete --filename examples/app.yaml

cat examples/crossplane-eks-production.yaml

echo "https://marketplace.upbound.io/configurations/devops-toolkit/dot-sql"
```

* Open the URL in a browser

```sh
kubectl --namespace a-team apply \
    --filename examples/crossplane-eks-production.yaml

crossplane beta trace clusterclaim production --namespace a-team
```

* We should not `apply` resources directly. We should use Argo CD, hence let's delete everything and start over.

```sh
kubectl --namespace a-team delete --filename examples/crossplane-eks-production.yaml
```

### Kratix

TODO:

### Backstage

```sh
# TODO: Generate examples/crossplane-eks-production.yaml and push it to Git to the `staging` directory

# TODO: Generate examples/app.yaml and push it to Git to the `staging` directory
```

### Argo CD

TODO:

## Destroy

```sh
kubectl --kubeconfig kubeconfig-staging.yaml \
    --namespace traefik delete service traefik

rm staging/*.yaml

git add .

git commit -m "Destroy"

git push

kubectl get managed

# Wait until all the managed resources are removed (ignore `object` resources)

eksctl delete cluster --config-file eksctl.yaml
```
