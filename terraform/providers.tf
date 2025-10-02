terraform {
  required_version = ">= 0.12"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }

  cloud {
    organization = "cedille"

    workspaces {
      name = "k8s-cedille-production-v2"
    }
  }
}

provider "github" {
  owner = var.gh_owner
  app_auth {
    id              = var.gh_app_id     # or `GITHUB_APP_ID`
    installation_id = var.gh_install_id # or `GITHUB_APP_INSTALLATION_ID`
    pem_file        = var.gh_pem        # or `GITHUB_APP_PEM_FILE`
  }
}