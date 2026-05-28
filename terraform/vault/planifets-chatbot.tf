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
# KV v2 secrets - Qdrant API key per environment
# ---------------------------------------------------------------------------
resource "vault_kv_secret_v2" "chatbot_qdrant" {
  for_each = local.envs

  mount = "kv"
  name  = "planifets-chatbot/${each.value.vault_path_env}/planifets-chatbot/qdrant"

  data_json = jsonencode({
    api_key = each.value.qdrant_api_key
  })
}
