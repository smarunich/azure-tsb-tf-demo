
data "google_compute_subnetwork" "wait_for_compute_apis_to_be_ready" {
  self_link = var.vpc_subnet
  project   = var.project_id
  region    = var.region
}

# doing dependency for google_compute_zones data to wait for compute api readiness... or expose zone from gcp_base module... 
data "google_compute_zones" "available" {
  project = var.project_id
  region  = data.google_compute_subnetwork.wait_for_compute_apis_to_be_ready.region
}

resource "tls_private_key" "generated" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

data "google_compute_default_service_account" "default" {
  project = var.project_id
  depends_on = [
    data.google_compute_subnetwork.wait_for_compute_apis_to_be_ready
  ]
}

module "internal_registry" {
  source      = "../../internal_registry"
  tsb_version = var.tsb_version
  # The internal registry token is needed only if the TSB version is a development version, and only once when the
  # jumpbox bootstraps the first time. It is not needed later as all images are already pushed to the registry (and
  # cloud-init won't run again anyway).
  # Since the token is short-lived, successive calls to this module would cause the jumpbox to reconcile, restart, and
  # eventually changing the IP address, etc, unnecessarily.
  # By setting this, subsequent calls to this module will return the token returned on the initial run, if present, avoiding
  # the jumbox reconcile.
  cached_by = "${var.name_prefix}-internal-registry.tfstate.tokencache"
}

resource "google_compute_instance" "jumpbox" {
  project      = var.project_id
  name         = "${var.name_prefix}-jumpbox"
  machine_type = var.machine_type
  zone         = data.google_compute_zones.available.names[0]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-minimal-2204-lts"
    }
  }

  network_interface {
    network    = var.vpc_id
    subnetwork = var.vpc_subnet
    access_config {
      // Ephemeral public IP
    }
  }

  # image support required for user-data https://cloud.google.com/container-optimized-os/docs/how-to/create-configure-instance
  # shortcut for demo purposes

  #metadata_startup_script = "sudo apt-get update; sudo apt-get install -yq cloud-init; sudo curl -o /etc/cloud/cloud.cfg.d/jumpbox.userdata  http://metadata/computeMetadata/v1/instance/attributes/user-data -H'Metadata-Flavor:Google'; sudo cloud-init -d init; sudo cloud-init -d modules --mode final; /opt/bootstrap.sh"

  metadata = {
    user-data = templatefile("${path.module}/jumpbox.userdata", {
      jumpbox_username          = var.jumpbox_username
      tsb_version               = var.tsb_version
      tsb_image_sync_username   = var.tsb_image_sync_username
      tsb_image_sync_apikey     = var.tsb_image_sync_apikey
      docker_login              = "gcloud auth configure-docker -q"
      registry                  = var.registry
      pubkey                    = tls_private_key.generated.public_key_openssh
      tsb_helm_repository       = var.tsb_helm_repository
      tetrate_internal_cr       = module.internal_registry.internal_cr
      tetrate_internal_cr_token = module.internal_registry.internal_cr_token
    })
  }

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = data.google_compute_default_service_account.default.email
    scopes = ["cloud-platform"]
  }

  labels = merge(var.tags, {
    name = "${var.name_prefix}-jumpbox"
  })
}

# GCP project deletion will fail, if there are any outstanding PVCs left post GKE cluster deletion, i.e. PVC for Postgres and Elasticsearch post TSB MP deletion
resource "null_resource" "gcp_cleanup" {
  triggers = {
    project_id = var.project_id
  }

  provisioner "local-exec" {
    when       = destroy
    command    = "sh ${path.module}/gcp-cleanup.sh ${self.triggers.project_id}"
    on_failure = continue
  }
  depends_on = [tls_private_key.generated]
}


resource "local_file" "tsbadmin_pem" {
  content         = tls_private_key.generated.private_key_pem
  filename        = "${var.output_path}/${var.name_prefix}-gcp-${var.jumpbox_username}.pem"
  depends_on      = [tls_private_key.generated]
  file_permission = "0600"
}

resource "local_file" "ssh_jumpbox" {
  content         = "ssh -i ${var.name_prefix}-gcp-${var.jumpbox_username}.pem -l ${var.jumpbox_username} ${google_compute_instance.jumpbox.network_interface[0].access_config[0].nat_ip} \"$@\""
  filename        = "${var.output_path}/ssh-to-gcp-${var.name_prefix}-jumpbox.sh"
  file_permission = "0755"
}
