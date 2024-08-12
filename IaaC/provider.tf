terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0.0"
    }
    keycloak = {
      source  = "mrparkers/keycloak"
      version = ">= 4.0.0"
    }

    k8s = {
      source  = "metio/k8s"
      version = "2022.11.21"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}


provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "kind-mm-local-cluster"
}
