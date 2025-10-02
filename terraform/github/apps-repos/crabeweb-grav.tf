resource "github_repository" "repo_crabeweb" {
  name = "crabe.demo.prodv2.cedille.club"
  auto_init = true
  homepage_url = "https://crabe.demo.prodv2.cedille.club"
  description = "Site web de crabeweb"
  has_downloads = true
  has_issues = true
  has_projects = true
  has_wiki = true
  security_and_analysis {
    secret_scanning {
      status = "enabled"
    }
    secret_scanning_push_protection {
      status = "enabled"
    }
  }
  topics = [ "grav" ]
  vulnerability_alerts = true
  visibility = "public"
}

resource "github_repository_webhook" "webhook_crabeweb" {
  repository = github_repository.repo_crabeweb.name

  configuration {
    url          = "https://crabe.demo.prodv2.cedille.club/_git_webhook"
    content_type = "json"
    insecure_ssl = false
  }

  active = true

  events = ["push"]
}

resource "github_repository_dependabot_security_updates" "dependabot_crabeweb" {
  repository  = github_repository.repo_crabeweb.name
  enabled     = true
}

resource "github_repository_collaborators" "colaborators_crabeweb" {
  repository = github_repository.repo_crabeweb.name

  team {
    permission = "admin"
    team_id = "sre"
  }
}
