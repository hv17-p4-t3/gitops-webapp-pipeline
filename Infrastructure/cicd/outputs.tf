output "jenkins_url" { value = module.jenkins_platform.jenkins_url }
output "jnlp_endpoint" { value = module.jenkins_platform.jnlp_endpoint }
output "master_cluster_arn" { value = module.jenkins_platform.master_cluster_arn }
output "agent_cluster_arn" { value = module.jenkins_platform.agent_cluster_arn }
output "agent_task_definition_arn" { value = module.jenkins_platform.agent_task_definition_arn }
output "agent_sg_id" { value = module.jenkins_platform.agent_sg_id }
