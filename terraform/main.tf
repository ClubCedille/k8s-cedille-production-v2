module "github" {
  source = "./github"
}

module "vault" {
  source = "./vault"

  chatbot_dev_qdrant_api_key      = var.chatbot_dev_qdrant_api_key
  chatbot_staging_qdrant_api_key  = var.chatbot_staging_qdrant_api_key
  chatbot_prod_qdrant_api_key     = var.chatbot_prod_qdrant_api_key
}
