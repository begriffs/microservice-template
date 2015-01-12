variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "grafana-ami" {
  default = "ami-9bf5eade"
}

variable "consul-ami" {
  default = "ami-e3c2dda6"
}

variable "influx-ami" {
  default = "ami-6f98872a"
}

variable "key_name" {
  description = "Name of the keypair to use in EC2."
  default = "terraform"
}
