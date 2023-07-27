variable "cloud" {
  type    = string
  default = "azure"
}

variable "cluster_id" {
  type    = string
  default = null
}

variable "azure_k8s_region" {
  default = []
}

locals {
  k8s_region = var.azure_k8s_region
}