resource "google_service_account" "external_dns" {
  project      = var.project_id
  account_id   = "${var.name_prefix}-external-dns"
}

resource "google_dns_managed_zone" "cluster" {
  project    = var.project_id
  name       = "${var.cluster_name}-${local.zone_name}"
  dns_name   = "${var.cluster_name}.${local.dns_name}."
  labels     = merge(var.tags, {
          name = "${var.cluster_name}-${local.zone_name}"
  })
}

data "google_dns_managed_zone" "shared" {
  project      = "dns-terraform-sandbox"
  name         = local.zone_name
}

resource "google_dns_record_set" "ns" {
  managed_zone = data.google_dns_managed_zone.shared.name
  project      = "dns-terraform-sandbox"
  name         = google_dns_managed_zone.cluster.dns_name
  type         = "NS"
  ttl          = 300
  rrdatas      = google_dns_managed_zone.cluster.name_servers
}

resource "google_project_iam_member" "dns_admin" {
  project   = var.project_id
  role      = "roles/dns.admin"
  member    = "serviceAccount:${google_service_account.external_dns.email}"
}

resource "google_service_account_key" "external_dns_key" {
  service_account_id = google_service_account.external_dns.name
}

provider "helm" {
  kubernetes {
    host                   = var.k8s_host
    cluster_ca_certificate = base64decode(var.k8s_cluster_ca_certificate)
    token                  = var.k8s_client_token
  }
}

resource "helm_release" "external_dns" {
  name             = "external-dns"
  repository       = "oci://registry-1.docker.io/bitnamicharts/"
  chart            = "external-dns"
  create_namespace = true
  namespace        = "external-dns"
  timeout          = 900

  set {
    name  = "policy"
    value = "upsert-only"
  }

  set {
    name  = "registry"
    value = "txt"
  }

  set {
    name  = "txtOwnerId"
    value = var.cluster_name
  }

  # Since we are enabling the Istio Gateway source, it is important to set this filter
  # so we don't create DNS records for any random or internal hostnames defined in
  # the TSB IngressGateways.

  set {
    name  = "domainFilters"
    value = "{${google_dns_managed_zone.cluster.dns_name}}"
  }

  set {
    name  = "sources"
    value = "{${var.sources}}"
  }

  set {
    name  = "annotationFilter"
    value = var.annotation_filter
  }

  set {
    name  = "labelFilter"
    value = var.label_filter
  }

  set {
    name  = "interval"
    value = var.interval
  }

  values = [templatefile("${path.module}/manifests/values.yaml.tmpl", {
    google_project             = var.project_id
    google_service_account_key = indent(4, base64decode(google_service_account_key.external_dns_key.private_key))
  })]
}

resource "null_resource" "gcp_cleanup" {
  triggers = {
    project_id = var.project_id
  }

  provisioner "local-exec" {
    when = destroy
    command = "sh ${path.module}/external-dns-gcp-cleanup.sh ${self.triggers.project_id}"
    on_failure = continue
  }
  depends_on = [ google_dns_managed_zone.cluster ]
}
