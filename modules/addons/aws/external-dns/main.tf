resource "aws_route53_zone" "cluster" {
  name   = "${var.cluster_name}.${var.dns_zone}"
  tags   = merge(var.tags, {
          Name = "${var.cluster_name}.${var.dns_zone}"
  })
}

data "aws_route53_zone" "shared" {
  name   = var.dns_zone
}

resource "aws_route53_record" "ns" {
  zone_id = data.aws_route53_zone.shared.zone_id
  name    = aws_route53_zone.cluster.name
  type    = "NS"
  ttl     = 300
  records = aws_route53_zone.cluster.name_servers
}

provider "helm" {
  kubernetes {
    host                   = var.k8s_host
    cluster_ca_certificate = base64decode(var.k8s_cluster_ca_certificate)
    token                  = var.k8s_client_token
  }
}

module "external_dns_helm" {
  source                   = "lablabs/eks-external-dns/aws"
  argo_enabled             = false
  argo_helm_enabled        = false
  irsa_assume_role_enabled = false
  irsa_role_name_prefix    = var.cluster_name

  cluster_identity_oidc_issuer     = var.cluster_oidc_issuer_url
  cluster_identity_oidc_issuer_arn = var.oidc_provider_arn
  irsa_tags                        = var.tags

  helm_release_name       = "external-dns"
  helm_repo_url           = "oci://registry-1.docker.io/bitnamicharts/"
  helm_chart_name         = "external-dns"
  helm_create_namespace   = true
  namespace               = "external-dns"
  helm_timeout            = "900"
  helm_wait               = true

  values = yamlencode({
    "policy": "upsert-only"
    "registry" : "txt"
    "txtOwnerId" : var.cluster_name
    "domainFilters": [aws_route53_zone.cluster.name]
    "sources": [var.sources]
    "annotationFilter": var.annotation_filter
    "labelFilter": var.label_filter
    "provider" : "aws"
    "interval" : var.interval
  })
}

resource "local_file" "aws_cleanup" {
  content = templatefile("${path.module}/external-dns_aws_cleanup.sh.tmpl", {
    name_prefix   = "eks-${regex(".+-",var.name_prefix)}"
  })
  filename        = "${var.output_path}/${var.name_prefix}-external-dns-aws-cleanup.sh"
  file_permission = "0755"
}

resource "null_resource" "aws_cleanup" {
  triggers = {
    output_path = var.output_path
    name_prefix = var.name_prefix
  }

  provisioner "local-exec" {
    when = destroy
    command = "sh ${self.triggers.output_path}/${self.triggers.name_prefix}-external-dns-aws-cleanup.sh"
    on_failure = continue
  }

  depends_on = [ local_file.aws_cleanup, aws_route53_zone.cluster ]
}
