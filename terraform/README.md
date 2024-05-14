# Kratix, Crossplane and ArgoCD on EKS

Deploy Amazon EKS with addons configured via ArgoCD.
ArgoCD is used to deploy Kratix and Crossplane with AWS Providers configured with IRSA.


## Deploy EKS Cluster

```shell
terraform init
terraform apply
```

## Access Terraform output to configure `kubectl` and `argocd`

```shell
terraform output
```

## Destroy EKS Cluster

```shell
./destroy.sh
```

### Reference

- <https://github.com/gitops-bridge-dev>
