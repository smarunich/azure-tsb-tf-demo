variable "name_prefix" {
  description = "name prefix"
}

variable "cluster_name" {
  description = "cluster name"
}

variable "output_path" {
}

variable "resource_group_name" {
}

variable "resource_group_id" {
}

variable "k8s_host" {
}

variable "k8s_cluster_ca_certificate" {
}

variable "k8s_client_token" {
}

variable "kubelet_identity" {
}

variable "tags" {
  type = map
}

variable "dns_zone" {
}

variable "annotation_filter" {
}

variable "label_filter" {
}

variable "sources" {
}

variable "interval" {
}

locals {
  dns_name      = var.dns_zone
  zone_name     = replace(local.dns_name, ".", "-")
}