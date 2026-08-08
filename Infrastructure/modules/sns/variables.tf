variable "topic_name" { type = string }

variable "subscriptions" {
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
