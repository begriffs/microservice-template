variable "key_name" { }
variable "rabbitmq_ami" { }

variable "vpc_id" { }
variable "subnet_id" { }
variable "sg_consul_id" { }
variable "sg_ssh_id" { }

resource "aws_security_group" "rabbitmq" {
  name = "rabbitmq"
  description = "Open up rabbitmq server"
  vpc_id = "${var.vpc_id}"

  # ampq
  ingress {
    from_port = 5672
    to_port = 5672
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # management console
  ingress {
    from_port = 15672
    to_port = 15672
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_instance" "rabbitmq" {
  instance_type = "t2.micro"
  key_name = "${var.key_name}"
  subnet_id = "${var.subnet_id}"

  ami = "${var.rabbitmq_ami}"
  security_groups = ["${aws_security_group.rabbitmq.id}",
                     "${var.sg_consul_id}",
                     "${var.sg_ssh_id}"]
}
