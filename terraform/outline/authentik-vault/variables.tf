variable "authentik_api_token" {
  type = string
  sensitive = true
}

variable "nom_club" {
  type = string
}

variable "client_id" {
  type = string
}

variable "TERRAFORM_VAULT_TOKEN_FILENAME" {
  type = string
  sensitive = true
}
