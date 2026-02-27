terraform {
  required_providers {
    authentik = {
      source = "goauthentik/authentik"
      version = "2025.12.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.8.1"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "5.7.0"
    }
  }
}

provider "authentik" {
  # Configuration options
  url = "https://auth.etsmtl.club"
  token = var.authentik_api_token
}

# Creates the OIDC client_secret inside Vault
provider "vault" {
  address = "https://vault.prodv2.cedille.club"
  auth_login_token_file {
    filename = var.TERRAFORM_VAULT_TOKEN_FILENAME
  }
}

resource "random_password" "outline_client_secret" {
  keepers = {
      club_name = var.nom_club
  }

  length = 48
  special = true
  override_special = "!-_="
}

resource "vault_generic_secret" "outline-oidc" {
  path = "kv/kubernetes/outline/${var.nom_club}"

  data_json = jsonencode({
    client_id = var.client_id
    client_secret = random_password.outline_client_secret.result
  })
}


# Creates the Application and the Provider inside Authentik
data "authentik_flow" "default-authorization-flow" {
  slug = "default-provider-authorization-explicit-consent"
}

data "authentik_flow" "default-invalidation-flow" {
  slug = "default-provider-invalidation-flow"
}

resource "authentik_provider_oauth2" "name" {
  name      = "outline-${var.nom_club}"
  client_id = var.client_id
  client_secret = random_password.outline_client_secret.result
  authorization_flow = data.authentik_flow.default-authorization-flow.id
  invalidation_flow = data.authentik_flow.default-invalidation-flow.id
}

resource "authentik_application" "name" {
  name              = "Wiki ${var.nom_club}"
  slug              = "outline-${var.nom_club}"
  protocol_provider = authentik_provider_oauth2.name.id
}
