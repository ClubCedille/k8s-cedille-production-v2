locals {
  envs = {
    dev = {
      namespace      = "planifets-chatbot-dev"
      vault_path_env = "dev"
      qdrant_api_key = var.chatbot_dev_qdrant_api_key
    }
    staging = {
      namespace      = "planifets-chatbot-staging"
      vault_path_env = "staging"
      qdrant_api_key = var.chatbot_staging_qdrant_api_key
    }
    prod = {
      namespace      = "planifets-chatbot"
      vault_path_env = "default"
      qdrant_api_key = var.chatbot_prod_qdrant_api_key
    }
  }
}

# ---------------------------------------------------------------------------
# Vault policies — allow read on each environment's KV path
# ---------------------------------------------------------------------------
resource "vault_policy" "chatbot" {
  for_each = local.envs

  name = "planifets-chatbot-${each.key}"

  policy = <<-EOT
    path "kv/data/planifets-chatbot/${each.value.vault_path_env}/*" {
      capabilities = ["read"]
    }
    path "kv/metadata/planifets-chatbot/${each.value.vault_path_env}/*" {
      capabilities = ["read", "list"]
    }
  EOT
}

# ---------------------------------------------------------------------------
# Kubernetes auth roles — bind default SA in each namespace to its policy
# ---------------------------------------------------------------------------
resource "vault_kubernetes_auth_backend_role" "chatbot" {
  for_each = local.envs

  backend                          = "kubernetes"
  role_name                        = "planifets-chatbot-${each.key}-secret-reader"
  bound_service_account_names      = ["default"]
  bound_service_account_namespaces = [each.value.namespace]
  token_policies                   = [vault_policy.chatbot[each.key].name]
  token_ttl                        = 3600
}

# ---------------------------------------------------------------------------
# KV v2 secrets — Qdrant API key per environment
# ---------------------------------------------------------------------------
resource "vault_kv_secret_v2" "chatbot_qdrant" {
  for_each = local.envs

  mount = "kv"
  name  = "planifets-chatbot/${each.value.vault_path_env}/planifets-chatbot/qdrant"

  data_json = jsonencode({
    api_key = each.value.qdrant_api_key
  })
}
