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

export KUBECONFIG=$PWD/kubeconfig.yaml

eksctl create cluster --config-file eksctl.yaml \
    --kubeconfig $KUBECONFIG

kubectl create namespace a-team
```

### Crossplane

```sh
helm upgrade --install crossplane crossplane \
    --repo https://charts.crossplane.io/stable \
    --namespace crossplane-system --create-namespace --wait

kubectl apply \
    --filename crossplane-config/provider-kubernetes-incluster.yaml

kubectl apply \
    --filename crossplane-config/provider-helm-incluster.yaml

kubectl apply --filename crossplane-config/config-sql.yaml

sleep 60

kubectl wait --for=condition=healthy provider.pkg.crossplane.io \
    --all --timeout=600s

kubectl --namespace crossplane-system \
    create secret generic aws-creds \
    --from-file creds=./aws-creds.conf

kubectl apply \
    --filename crossplane-config/provider-config-aws.yaml
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

cat app/*.yaml

echo "https://marketplace.upbound.io/configurations/devops-toolkit/dot-sql"
```

* Open the URL in a browser

```sh
kubectl --namespace a-team apply --filename app/

kubectl --namespace a-team get all,sqlclaims

crossplane beta trace sqlclaim silly-demo --namespace a-team
```

* We should not `apply` resources directly. We should use Argo CD, hence let's delete everything and start over.

```sh
kubectl --namespace a-team delete --filename app/
```

### Kratix

TODO:

### Backstage

TODO:

### Argo CD

TODO:

## Destroy

```sh
eksctl delete cluster --config-file eksctl.yaml
```
