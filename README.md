# London Workshop

## Prerequisites

* Shell terminal (use WSL if on Windows)
* Git
* [Devbox](https://www.jetify.com/devbox/docs/installing_devbox)

## Setup

### Common

Environment variables:
```bash
git clone https://github.com/vfarcic/london-2024

cd london-2024
devbox shell

ROOT=$(pwd)

# Replace `[...]` with the AWS Access Key ID
export AWS_ACCESS_KEY_ID=[...]

# Replace `[...]` with the AWS Secret Access Key
export AWS_SECRET_ACCESS_KEY=[...]

export KUBECONFIG=${ROOT}/kubeconfig-hub-cluster.yaml
```

### Cluster creation and bootstrapping

Attendees will be provided an AWS account using the setup described in `./terraform/README.md`.
This code is executable on personal accounts as well as long as AWS account credentials are correctly set.

Separately, if you prefer to do a more step by step setup, you can follow the instructions in `./localenv/README.md`

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
echo "https://us-west-2.console.aws.amazon.com/ec2/home?region=us-west-2"
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

cat examples/sql.yaml

kubectl --namespace a-team apply --filename examples/sql.yaml

./crossplane beta trace sqlclaim silly-demo --namespace a-team
```

* We should not `apply` resources directly. We should use Argo CD, hence let's delete everything and start over.

```sh
kubectl --namespace a-team delete --filename examples/sql.yaml

cat examples/crossplane-eks-production.yaml

echo "https://marketplace.upbound.io/configurations/devops-toolkit/dot-sql"
```

* Open the URL in a browser

```sh
kubectl --namespace a-team apply \
    --filename examples/crossplane-eks-production.yaml

./crossplane beta trace clusterclaim production --namespace a-team
```

* We should not `apply` resources directly. We should use Argo CD, hence let's delete everything and start over.

```sh
kubectl --namespace a-team delete --filename examples/crossplane-eks-production.yaml
```

### Kratix

At the most simple, Kratix is a gitops writer, so let's do that...

```sh
# TODO: Base Promise with Crossplane files in the resource workflow + environment field in the API

# To use "Crossplane Files":
# TODO: Generate examples/sql.yaml and push it to Git to the `hub` directory

# TODO: Take `silly-demo` secret from the Hub cluster (after the DB was created) in the `a-team` Namespace and push it to the `staging` directory. Alternatively, encrypt it with SealedSecrets (if we want to complicate it more).

# TODO: Generate examples/crossplane-eks-production.yaml and push it to Git to the `hub` directory

# TODO: Generate examples/app.yaml and push it to Git to the `staging` directory
```

Yay, now we have our Crossplane resources staying reconciled both from Crossplane to AWS but also from our intention to Crossplane.

Now let's build in the need for manual approval in production
```sh
# TODO: add container for manual approval
```

### Backstage

```sh
# TODO: Generate a template that matches the Kratix API form
# TODO: When someone creates from this template, make a commit to the git repo
# TODO: Make sure the items created by Kratix/Crossplane show up in the catalog as you wish
```

### Argo CD

TODO:

## Destroy

Follow the destroy instructions in the relevant readme (`./terraform/README.md` or `./localdev/README.md`)
