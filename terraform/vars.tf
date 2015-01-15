variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "grafana-ami" {
  default = ""
}

variable "consul-ami" {
  default = ""
}

variable "influx-ami" {
  default = ""
}

variable "statsd-ami" {
  default = ""
}

variable "key_name" {
  description = "Name of the keypair to use in EC2."
  default = "terraform"
}
