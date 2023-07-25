variable "cloud" {
  default = null
}

variable "cluster_id" {
  default = null
}

variable "name_prefix" {
  description = "name prefix"
}

variable "output_path" {
  default = "../../../outputs"
}

variable "tsb_image_sync_username" {
}

variable "gcp_k8s_regions" {
  default = []
}

locals {
  k8s_regions = var.gcp_k8s_regions
}

variable "tetrate_owner" {
}
variable "tetrate_team" {
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
       tetrate_owner     = coalesce(var.tetrate_owner, replace(var.tsb_image_sync_username, "/\\W+/", "-"))
       tetrate_team      = replace(var.tetrate_team, "/\\W+/", "-")
       tetrate_purpose   = var.tetrate_purpose
       tetrate_lifespan  = var.tetrate_lifespan
       tetrate_customer  = var.tetrate_customer
       environment       = var.name_prefix
  }
}

variable "external_dns_annotation_filter" {
  default = ""
}

variable "external_dns_label_filter" {
  default = ""
}

variable "external_dns_sources" {
  default = "service"
}

variable "external_dns_interval" {
  default = "5s"
}

variable "external_dns_gcp_dns_zone" {
  default = "gcp.sandbox.tetrate.io"
}

