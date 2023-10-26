data "terraform_remote_state" "infra" {
  backend = "local"
  config = {
    path = "../../../infra/${local.cluster.cloud}/terraform.tfstate.d/${local.cluster.workspace}/terraform.tfstate"
  }
}

data "terraform_remote_state" "k8s_auth" {
  backend = "local"
  config = {
    path = "../../../infra/${local.cluster.cloud}/k8s_auth/terraform.tfstate.d/${local.cluster.workspace}/terraform.tfstate"
  }
}

module "external_dns" {
  source                     = "../../../modules/addons/gcp/external-dns"
  name_prefix                = "${var.name_prefix}-${local.cluster.index}"
  cluster_name               = data.terraform_remote_state.infra.outputs.cluster_name
  k8s_host                   = data.terraform_remote_state.infra.outputs.host
  k8s_cluster_ca_certificate = data.terraform_remote_state.infra.outputs.cluster_ca_certificate
  k8s_client_token           = data.terraform_remote_state.k8s_auth.outputs.token
  project_id                 = data.terraform_remote_state.infra.outputs.project_id
  tags                       = local.tags
  dns_zone                   = local.addon_config.dns_zone
  sources                    = local.addon_config.dns_sources
  annotation_filter          = local.addon_config.dns_annotation_filter
  label_filter               = local.addon_config.dns_label_filter
  interval                   = local.addon_config.dns_interval
  output_path                = var.output_path
}