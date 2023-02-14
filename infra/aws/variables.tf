variable "cloud" {
  default = null
}
variable "cluster_id" {
  default = null
}
variable "cluster_name" {
  default = null
}

variable "name_prefix" {
  description = "name prefix"
}

variable "cidr" {
  description = "cidr"
  default     = "172.20.0.0/16"
}

variable "tsb_image_sync_username" {
}

variable "tsb_image_sync_apikey" {
}

variable "tsb_username" {
  default = "admin"
}

variable "tsb_password" {
  default = ""
}

variable "tsb_version" {
  default = "1.5.0"
}
variable "tsb_helm_repository" {
  default = "https://charts.dl.tetrate.io/public/helm/charts/"
}
variable "tsb_helm_version" {
  default = null
}
variable "tsb_fqdn" {
  default = "toa.sandbox.tetrate.io"
}
variable "dns_zone" {
  default = .sandbox.tetrate.io"
}

variable "tsb_org" {
  default = "tetrate"
}

variable "mp_as_tier1_cluster" {
  default = true
}
variable "jumpbox_username" {
  default = "tsbadmin"
}

variable "aws_k8s_regions" {
  default = []
}

# variable to communicated over a workspace only
variable "aws_k8s_region" {
  default = null
}

variable "azure_k8s_regions" {
  default = []
}

variable "aws_eks_k8s_version" {
  default = "1.23"
}

variable "tsb_mp" {
  default = {
    cloud      = "azure"
    cluster_id = 0
  }
}

variable "output_path" {
  default = "../../outputs"
}

variable "cert-manager_enabled" {
  default = true
}

variable "tetrate_owner" {
    default = null
}
variable "tetrate_team" {
    default = null
}
variable "tetrate_purpose" {
    default = "demo"
}
variable "tetrate_lifespan" {
    default = "oneoff"
}
variable "tetrate_customer" {
    default = "internal"
}
locals {
  default_tags = {
       "tetrate:owner"    = var.tetrate_owner
       "tetrate:team"     = var.tetrate_team
       "tetrate:purpose"  = var.tetrate_purpose
       "tetrate:lifespan" = var.tetrate_lifespan
       "tetrate:customer" = var.tetrate_customer
       "Environment"      = var.name_prefix
  }
}