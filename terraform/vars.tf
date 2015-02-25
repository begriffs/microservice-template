variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "region" {
  default="us-west-1"
}

variable "grafana_ami" {}
variable "consul_ami" {}
variable "influx_ami" {}
variable "statsd_ami" {}

variable "rabbitmq_ami" {}

variable "halcyon_ami" {
  default = ""
}

# To include halcyon workers set variable to number of workers
variable "halcyon_workers" {
  default = 0
}

variable "key_name" {
  description = "Name of the keypair to use in EC2."
  default = ""
}
