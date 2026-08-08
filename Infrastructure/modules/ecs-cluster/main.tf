resource "aws_ecs_cluster" "this" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights
  }

  tags = merge(var.common_tags, { Name = var.cluster_name })
}
