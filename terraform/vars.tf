variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "grafana-ami" {
  default = "ami-adbba7e8"
}

variable "key_name" {
  description = "Name of the keypair to use in EC2."
  default = "terraform"
}
