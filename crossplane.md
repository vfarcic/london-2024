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
kind create cluster

kubectl create namespace a-team
```

### Hub Crossplane

```sh
helm upgrade --install crossplane crossplane \
    --repo https://charts.crossplane.io/stable \
    --namespace crossplane-system --create-namespace --wait

kubectl apply \
    --filename crossplane-config/provider-kubernetes-incluster.yaml

kubectl apply \
    --filename crossplane-config/provider-helm-incluster.yaml

kubectl apply --filename crossplane-config/config-sql.yaml

kubectl apply --filename crossplane-config/config-kubernetes.yaml

sleep 60

kubectl wait --for=condition=healthy provider.pkg.crossplane.io \
    --all --timeout=600s

kubectl --namespace crossplane-system \
    create secret generic aws-creds \
    --from-file creds=./aws-creds.conf

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
kubectl --namespace a-team apply \
    --filename examples/crossplane-eks-staging.yaml

crossplane beta trace clusterclaim staging --namespace a-team

# Wait until all the resources are available

export KUBECONFIG=$PWD/kubeconfig-staging.yaml

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

kubectl --namespace a-team apply \
    --filename examples/crossplane-eks-staging.yaml

echo "http://argocd.$INGRESS_IP.nip.io"

# Open it in a browser
# Use `admin` as the username and `admin123` as the password
```

## Workshop

Workshop starts here.

### Crossplane

```sh
kubectl get pkg

kubectl get crds | grep aws

cat examples/crossplane-vm.yaml

kubectl apply --filename examples/crossplane-vm.yaml

kubectl get instances,instancestates,vpcs,subnets

echo "https://marketplace.upbound.io/providers/upbound/provider-aws-ec2"
```

* Open the URL in a browser

```sh
echo "https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1"
```

* Open the URL in a browser

* Stop the VM
* Observe that it started again

```sh
kubectl delete --filename examples/crossplane-vm.yaml

cat examples/crossplane-eks-production.yaml

kubectl --namespace a-team apply \
    --filename examples/crossplane-eks-production.yaml

echo "https://marketplace.upbound.io/configurations/devops-toolkit/dot-kubernetes"
```

* Open the URL in a browser

```sh
cat examples/app.yaml

cat examples/crossplane-sql.yaml

kubectl --namespace a-team apply \
    --filename examples/crossplane-sql.yaml

crossplane beta trace sqlclaim silly-demo --namespace a-team
```

* We should not `apply` resources directly. We should use Argo CD, hence let's delete everything and start over.

```sh
echo "https://marketplace.upbound.io/configurations/devops-toolkit/dot-sql"
```

* Open the URL in a browser

```sh
crossplane beta trace clusterclaim production --namespace a-team

crossplane beta trace clusterclaim staging --namespace a-team

kubectl --kubeconfig kubeconfig-staging.yaml get namespaces
```

* We should not `apply` resources directly. We should use Argo CD, hence let's delete everything and start over.

## Destroy

```sh
kubectl --kubeconfig kubeconfig-staging.yaml \
    --namespace traefik delete service traefik

aws eks update-kubeconfig --region us-east-1 \
    --name production --kubeconfig kubeconfig-production.yaml

kubectl --kubeconfig kubeconfig-production.yaml \
    --namespace traefik delete service traefik

kubectl --namespace a-team delete \
    --filename examples/crossplane-eks-staging.yaml

kubectl --namespace a-team delete \
    --filename examples/crossplane-eks-production.yaml

kubectl --namespace a-team delete \
    --filename examples/crossplane-sql.yaml

kubectl get managed

# Wait until all the managed resources are removed (ignore `object` and `release` resources).

kind delete cluster
```
