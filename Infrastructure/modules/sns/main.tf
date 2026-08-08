resource "aws_sns_topic" "this" {
  name = var.topic_name
  tags = merge(var.common_tags, { Name = var.topic_name })
}

resource "aws_sns_topic_subscription" "this" {
  count     = length(var.subscriptions)
  topic_arn = aws_sns_topic.this.arn
  protocol  = var.subscriptions[count.index].protocol
  endpoint  = var.subscriptions[count.index].endpoint
}
