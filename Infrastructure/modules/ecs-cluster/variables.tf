variable "cluster_name" { type = string }

variable "enable_container_insights" {
  type    = string
  default = "enabled"
}

variable "common_tags" {
  type    = map(string)
  default = {}
}
