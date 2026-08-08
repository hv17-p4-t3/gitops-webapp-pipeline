include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_repo_root()}//Infrastructure/app"
}

inputs = {
  project_name = "gitops-pipeline"
  environment  = "prod"

  sns_subscriptions = [
    {
      protocol = "email"
      endpoint = "prod-alerts@example.com"
    }
  ]

  common_tags = {
    Project     = "gitops-pipeline"
    Environment = "prod"
    ManagedBy   = "terraform"
  }
}
