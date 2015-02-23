variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "region" {
  default="us-west-1"
}

variable "availability_zone" {
  default="us-west-1a"
}

variable "grafana_ami" {}
variable "consul_ami" {}
variable "influx_ami" {}
variable "statsd_ami" {}

variable "rabbitmq-ami" {
  default = ""
}

variable "halcyon-ami" {
  default = ""
}

variable "key_name" {
  description = "Name of the keypair to use in EC2."
  default = ""
}
