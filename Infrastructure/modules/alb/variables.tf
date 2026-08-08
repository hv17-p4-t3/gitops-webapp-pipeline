variable "name" { type = string }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "security_group_ids" { type = list(string) }
variable "target_port" { type = number }

variable "internal" {
  type    = bool
  default = false
}

variable "listener_port" {
  type    = number
  default = 80
}

variable "health_check_path" {
  type    = string
  default = "/"
}

variable "common_tags" {
  type    = map(string)
  default = {}
}
