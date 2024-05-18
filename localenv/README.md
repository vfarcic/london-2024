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
