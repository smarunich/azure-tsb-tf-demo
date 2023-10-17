# Copyright (c) Tetrate, Inc 2021 All Rights Reserved.

# Environment configuration
dry_run     ?= false
tfvars_json ?= terraform.tfvars.json

# Functions
.DEFAULT_GOAL := help

.PHONY: all
all: tsb

.PHONY: help
help: Makefile ## This help
	@awk 'BEGIN {FS = ":.*##"; printf "Usage:\n"} \
			/^[.a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36mmake %-25s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

.PHONY: init
init:  ## Terraform init
	@/bin/sh -c "export TFVARS_JSON="${tfvars_json}" && ./make/variables.sh"
	@echo "Please refer to the latest instructions and terraform.tfvars.json file format at https://github.com/tetrateio/tetrate-service-bridge-sandbox#usage"

.PHONY: k8s
k8s: aws_k8s azure_k8s gcp_k8s  ## Deploys cloud infra and k8s clusters for MP and N-number of CPs
%_k8s: init
	@/bin/sh -c 'export DRY_RUN="${dry_run}" TFVARS_JSON="${tfvars_json}" && ./make/infra.sh $*_k8s'

.PHONY: k8s_auth
k8s_auth: k8s_auth_aws k8s_auth_azure k8s_auth_gcp   ## Refreshes k8s auth token
k8s_auth_%:
	@/bin/sh -c 'export DRY_RUN="${dry_run}" TFVARS_JSON="${tfvars_json}" && ./make/k8s_auth.sh k8s_auth_$*'

.PHONY: tsb_mp
tsb_mp:  ## Onboards TSB Management Plane
	@echo "Refreshing k8s access tokens..."
	@$(MAKE) k8s_auth
	@echo "Onboarding TSB Management Plane..."
	@/bin/sh -c 'export DRY_RUN="${dry_run}" TFVARS_JSON="${tfvars_json}" && ./make/tsb.sh tsb_mp'

.PHONY: tsb_cp
tsb_cp: tsb_cp_aws tsb_cp_azure tsb_cp_gcp ## Onboards TSB Control and Data Plane
tsb_cp_%:
	@echo "Refreshing k8s access tokens..."
	@$(MAKE) k8s_auth
	@echo "Onboarding TSB Control and Data Plane on cloud $*..."
	@/bin/sh -c 'export DRY_RUN="${dry_run}" TFVARS_JSON="${tfvars_json}" && ./make/tsb.sh tsb_cp_$*'

.PHONY: tsb
tsb: k8s tsb_mp tsb_cp  ## Deploys full environment (MP+CP)
	@echo "Magic is on the way..."

.PHONY: argocd
argocd: argocd_aws argocd_azure argocd_gcp ## Deploys ArgoCD
argocd_%:
	@echo "Refreshing k8s access tokens..."
	@$(MAKE) k8s_auth_$*
	@echo "Deploying ArgoCD on cloud $*..."
	@/bin/sh -c 'export DRY_RUN="${dry_run}" TFVARS_JSON="${tfvars_json}" && ./make/addon.sh argocd_$*'

.PHONY: fluxcd
fluxcd: fluxcd_aws fluxcd_azure fluxcd_gcp ## Deploys FluxCD
fluxcd_%:
	@echo "Refreshing k8s access tokens..."
	@$(MAKE) k8s_auth_$*
	@echo "Deploying FluxCD on cloud $*..."
	@/bin/sh -c 'export DRY_RUN="${dry_run}" TFVARS_JSON="${tfvars_json}" && ./make/addon.sh fluxcd_$*'

.PHONY: tsb_monitoring
tsb_monitoring:  ## Deploys TSB monitoring stack
	@echo "Refreshing k8s access tokens..."
	@$(MAKE) k8s_auth
	@echo "Deploying TSB Monitoring"
	@/bin/sh -c 'export DRY_RUN="${dry_run}" TFVARS_JSON="${tfvars_json}" && ./make/addon.sh tsb_monitoring'

.PHONY: external-dns
external_dns: external_dns_aws external_dns_azure external_dns_gcp ## Deploys External DNS
external_dns_%:
	@echo "Refreshing k8s access tokens..."
	@$(MAKE) k8s_auth_$*
	@echo "Deploying External DNS on cloud $*..."
	@/bin/sh -c 'export DRY_RUN="${dry_run}" TFVARS_JSON="${tfvars_json}" && ./make/addon.sh external_dns_$*'

destroy_external_dns: destroy_external_dns_aws destroy_external_dns_azure destroy_external_dns_gcp ## Destroy External DNS
destroy_external_dns_%:
	@echo "Refreshing k8s access tokens..."
	@$(MAKE) k8s_auth_$*
	@echo "Destroying External DNS on cloud $*..."
	@/bin/sh -c 'export DRY_RUN="${dry_run}" TFVARS_JSON="${tfvars_json}" && ./make/addon.sh destroy_external_dns_$*'

.PHONY: destroy
destroy: destroy_remote destroy_local ## Destroy environment and local terraform state, cache and output artifacts

.PHONY: destroy_remote
destroy_remote:  ## Destroy environment
	@echo "Refreshing k8s access tokens..."
	@$(MAKE) k8s_auth
	@echo "Destroy TSB Management Plane FQDN..."
	@/bin/sh -c 'export DRY_RUN="${dry_run}" TFVARS_JSON="${tfvars_json}" && ./make/tsb.sh destroy_remote'
	@$(MAKE) destroy_external_dns
	@$(MAKE) destroy_aws destroy_azure destroy_gcp

.PHONY: destroy_local
destroy_local:  ## Destroy local Terraform state, cache and output artifacts
	@$(MAKE) destroy_tfstate
	@$(MAKE) destroy_tfcache
	@$(MAKE) destroy_outputs

.PHONY: destroy_aws
destroy_aws:  ## Destroy aws infrastructure
	@echo "Destroy aws infrastructure..."
	@/bin/sh -c 'export DRY_RUN="${dry_run}" TFVARS_JSON="${tfvars_json}" && ./make/infra.sh destroy_aws'

.PHONY: destroy_azure
destroy_azure:  ## Destroy azure infrastructure
	@echo "Destroy azure infrastructure..."
	@/bin/sh -c 'export DRY_RUN="${dry_run}" TFVARS_JSON="${tfvars_json}" && ./make/infra.sh destroy_azure'

.PHONY: destroy_gcp
destroy_gcp:  ## Destroy gcp infrastructure
	@echo "Destroy gcp infrastructure..."
	@/bin/sh -c 'export DRY_RUN="${dry_run}" TFVARS_JSON="${tfvars_json}" && ./make/infra.sh destroy_gcp'

.PHONY: destroy_tfstate
destroy_tfstate:
	@echo "Destroy terraform tfstate..."
	@/bin/sh -c 'export DRY_RUN="${dry_run}" TFVARS_JSON="${tfvars_json}" && ./make/destroy.sh destroy_tfstate'

.PHONY: destroy_tfcache
destroy_tfcache:
	@echo "Destroy terraform tfcache..."
	@/bin/sh -c 'export DRY_RUN="${dry_run}" TFVARS_JSON="${tfvars_json}" && ./make/destroy.sh destroy_tfcache'

.PHONY: destroy_outputs
destroy_outputs:
	@echo "Destroy terraform output artifacts..."
	@/bin/sh -c 'export DRY_RUN="${dry_run}" TFVARS_JSON="${tfvars_json}" && ./make/destroy.sh destroy_outputs'
