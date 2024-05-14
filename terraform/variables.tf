variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}
variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}
variable "aws_auth_roles" {
  description = "additional aws auth roles"
  type = list(
    object(
      {
        rolearn  = string
        username = string
        groups = list(string
        )
      }
    )
  )
  default = []
  # example structure
  #  {
  #     rolearn  = "arn:aws:iam::12345678901:role/role1"
  #     username = "role1"
  #     groups   = ["system:masters"]
  #   }
}
variable "addons" {
  description = "Kubernetes addons"
  type        = any
  default = {
    enable_aws_crossplane_provider         = true # installs aws contrib provider
    enable_aws_crossplane_upbound_provider = true # installs aws upbound provider
    enable_crossplane_kubernetes_provider  = true # installs kubernetes provider
    enable_crossplane_helm_provider        = true # installs helm provider
    enable_crossplane                      = true # installs crossplane core
    enable_cert_manager                    = true
    enable_aws_ebs_csi_resources           = true # generate gp2 and gp3 storage classes for ebs-csi
    enable_metrics_server                  = true
    enable_kratix                          = true
  }
}
# Addons Git
variable "gitops_addons_org" {
  description = "Git repository org/user contains for addons"
  type        = string
  default     = "https://github.com/ovaleanu"
}
variable "gitops_addons_repo" {
  description = "Git repository contains for addons"
  type        = string
  default     = "gitops-bridge-argocd-control-plane-template"
}
variable "gitops_addons_revision" {
  description = "Git repository revision/branch/ref for addons"
  type        = string
  default     = "main"
}
variable "gitops_addons_basepath" {
  description = "Git repository base path for addons"
  type        = string
  default     = ""
}
variable "gitops_addons_path" {
  description = "Git repository path for addons"
  type        = string
  default     = "bootstrap/control-plane/addons"
}

# Workloads Git
variable "gitops_workload_org" {
  description = "Git repository org/user contains for workload"
  type        = string
  default     = "https://github.com/vfarcic"
}
variable "gitops_workload_repo" {
  description = "Git repository contains for workload"
  type        = string
  default     = "london-2024"
}
variable "gitops_workload_revision" {
  description = "Git repository revision/branch/ref for workload"
  type        = string
  default     = "main"
}
variable "gitops_workload_basepath" {
  description = "Git repository base path for workload"
  type        = string
  default     = ""
}
variable "gitops_workload_path" {
  description = "Git repository path for workload"
  type        = string
  default     = "app"
}
