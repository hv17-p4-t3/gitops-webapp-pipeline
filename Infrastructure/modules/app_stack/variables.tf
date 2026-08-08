variable "project_name" { type = string }
variable "environment" { type = string }

variable "sns_subscriptions" {
  type = list(object({
    protocol = string
    endpoint = string
  }))
  default = []
}

variable "common_tags" {
  type    = map(string)
  default = {}
}
