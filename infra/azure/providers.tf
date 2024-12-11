terraform {
  required_providers {
    kubectl = {
      source  = "alekc/kubectl"
      version = "2.0.3"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "9a42948e-6087-47d2-bdb8-b530d558db22"
  
  /* default_tags {
    tags = local.tags
  } */
}
