variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" { type = string }
variable "environment" { type = string }
variable "vpc_cidr" { type = string }
variable "public_subnet_cidrs" { type = list(string) }
variable "private_subnet_cidrs" { type = list(string) }

variable "master_cpu" {
  type    = number
  default = 2048
}

variable "master_memory" {
  type    = number
  default = 4096
}

variable "master_image" {
  type    = string
  default = "jenkins/jenkins:lts-jdk21"
}

variable "agent_cpu" {
  type    = number
  default = 1024
}

variable "agent_memory" {
  type    = number
  default = 2048
}

variable "agent_image" {
  type    = string
  default = "jenkins/inbound-agent:latest-jdk21"
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "common_tags" {
  type    = map(string)
  default = {}
}

variable "jenkins_admin_user" {
  type    = string
  default = "admin"
}

variable "jenkins_admin_password" {
  type      = string
  sensitive = true
  default   = "admin"
}
