variable "key_name" { }
variable "statsd_ami" { }

variable "vpc_id" { }
variable "sg_consul_id" { }
variable "subnet_id" { }

resource "aws_security_group" "statsd" {
  name = "statsd"
  description = "Open up statsd udp"
  vpc_id = "${var.vpc_id}"

  # api access locally
  ingress {
    from_port = 8125
    to_port = 8125
    protocol = "udp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_instance" "statsd" {
  instance_type = "t2.micro"
  key_name = "${var.key_name}"
  subnet_id = "${var.subnet_id}"

  ami = "${var.statsd_ami}"
  security_groups = ["${aws_security_group.statsd.id}", "${var.sg_consul_id}"]

  /* lifecycle { create_before_destroy = true } */
}
