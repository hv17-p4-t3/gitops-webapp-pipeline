include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_repo_root()}//Infrastructure/cicd"
}

inputs = {
  project_name         = "gitops-jenkins"
  environment          = "dev"
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
  master_cpu           = 2048
  master_memory        = 4096
  master_image         = "512438352764.dkr.ecr.us-east-1.amazonaws.com/jenkins-master:latest"
  agent_cpu            = 1024
  agent_memory         = 2048
  log_retention_days   = 14

  common_tags = {
    Project     = "gitops-pipeline"
    Environment = "dev"
    ManagedBy   = "terraform"
  }

  jenkins_admin_user     = "Immrdg"
  jenkins_admin_password = "Immrdg@21"
}
