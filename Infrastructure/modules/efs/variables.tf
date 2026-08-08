variable "name" { type = string }
variable "subnet_ids" { type = list(string) }
variable "security_group_ids" { type = list(string) }

variable "encrypted" {
  type    = bool
  default = true
}

variable "performance_mode" {
  type    = string
  default = "generalPurpose"
}

variable "throughput_mode" {
  type    = string
  default = "bursting"
}

variable "posix_uid" {
  type    = number
  default = 1000
}

variable "posix_gid" {
  type    = number
  default = 1000
}

variable "root_directory_path" {
  type    = string
  default = "/data"
}

variable "common_tags" {
  type    = map(string)
  default = {}
}
