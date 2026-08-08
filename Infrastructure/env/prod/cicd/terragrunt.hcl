include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_repo_root()}//Infrastructure/cicd"
}

inputs = {
  project_name         = "gitops-jenkins"
  environment          = "prod"
  vpc_cidr             = "10.1.0.0/16"
  public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnet_cidrs = ["10.1.10.0/24", "10.1.11.0/24"]
  master_cpu           = 4096
  master_memory        = 8192
  agent_cpu            = 2048
  agent_memory         = 4096
  log_retention_days   = 90

  common_tags = {
    Project     = "gitops-pipeline"
    Environment = "prod"
    ManagedBy   = "terraform"
  }
}
