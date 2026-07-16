resource "github_repository" "repo_grav-smoke-test" {
  name = "grav-smoke-test.prodv2.cedille.club"
  auto_init = true
  homepage_url = "https://grav-smoke-test.prodv2.cedille.club"
  description = "Site web de grav-smoke-test"
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

resource "github_repository_webhook" "webhook_grav-smoke-test" {
  repository = github_repository.repo_grav-smoke-test.name

  configuration {
    url          = "https://grav-smoke-test.prodv2.cedille.club/_git_webhook"
    content_type = "json"
    insecure_ssl = false
  }

  active = true

  events = ["push"]
}

resource "github_repository_dependabot_security_updates" "dependabot_grav-smoke-test" {
  repository  = github_repository.repo_grav-smoke-test.name
  enabled     = true
}

resource "github_repository_collaborators" "colaborators_grav-smoke-test" {
  repository = github_repository.repo_grav-smoke-test.name

  team {
    permission = "admin"
    team_id = "sre"
  }
}
