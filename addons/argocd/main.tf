data "terraform_remote_state" "infra" {
  backend = "local"
  config = {
    path = "../../infra/${var.cloud}/terraform.tfstate.d/${var.cloud}-${var.cluster_id}-${local.k8s_regions[var.cluster_id]}/terraform.tfstate"
  }
}

module "argocd" {
  source                     = "../../modules/addons/argocd"
  cluster_name               = terraform_remote_state.infra.outputs.cluster_name
  k8s_host                   = terraform_remote_state.infra.outputs.host
  k8s_cluster_ca_certificate = terraform_remote_state.infra.outputs.cluster_ca_certificate
  k8s_client_token           = terraform_remote_state.infra.outputs.token
  password                   = var.tsb_password
}
