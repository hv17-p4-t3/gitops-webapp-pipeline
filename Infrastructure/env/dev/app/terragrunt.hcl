include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_repo_root()}//Infrastructure/app"
}

inputs = {
  project_name = "gitops-pipeline"
  environment  = "dev"

  sns_subscriptions = [
    {
      protocol = "email"
      endpoint = "d.gireesh21@gmail.com"
    }
  ]

  common_tags = {
    Project     = "gitops-pipeline"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
