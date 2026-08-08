# App Stack Orchestrator
# Composes leaf modules for application infrastructure

module "notifications" {
  source     = "../sns"
  topic_name = "${var.project_name}-notifications-${var.environment}"

  subscriptions = var.sns_subscriptions

  common_tags = var.common_tags
}
