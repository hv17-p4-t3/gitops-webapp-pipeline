output "jenkins_url" {
  description = "Jenkins web UI URL via ALB"
  value       = "http://${module.alb.lb_dns_name}"
}

output "jnlp_endpoint" {
  description = "Internal NLB DNS for agent JNLP connection (use as tunnel)"
  value       = "${module.nlb.lb_dns_name}:50000"
}

output "master_cluster_arn" { value = module.master_cluster.cluster_arn }
output "agent_cluster_arn" { value = module.agent_cluster.cluster_arn }
output "agent_task_definition_arn" { value = aws_ecs_task_definition.agent.arn }
output "agent_sg_id" { value = aws_security_group.agent.id }
output "vpc_id" { value = module.vpc.vpc_id }
output "public_subnet_ids" { value = module.vpc.public_subnet_ids }
