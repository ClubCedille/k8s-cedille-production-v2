
variable "gh_owner" {
  type = string
}

variable "gh_app_id" {
  type = string
}

variable "gh_install_id" {
  type = string
}

variable "gh_pem" {
  type      = string
  sensitive = true
}

variable "vault_address" {
  type        = string
  description = "URL of the Vault server (e.g. https://vault.prodv2.cedille.club)"
  default     = "https://vault.prodv2.cedille.club"
}

variable "vault_token" {
  type        = string
  sensitive   = true
  description = "Vault token with write access to kv/ and sys/policy/ and auth/kubernetes/role/"
  default     = ""
}
