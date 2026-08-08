variable "name" { type = string }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "target_port" { type = number }
variable "listener_port" { type = number }

variable "internal" {
  type    = bool
  default = true
}

variable "common_tags" {
  type    = map(string)
  default = {}
}
