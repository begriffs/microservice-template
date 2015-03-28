variable "region" {
  default="us-west-1"
}

variable "key_name" { }
variable "influx_ami" { }
variable "grafana_ami" { }

variable "vpc_id" { }
variable "sg_consul_id" { }
variable "sg_ssh_id" { }
variable "sg_public_ssh_id" { }
variable "subnet_id" { }

resource "aws_security_group" "monitor_bastion" {
  vpc_id = "${var.vpc_id}"
  name = "public"
  description = "SSH and HTTP from everywhere"

  # HTTP access from anywhere
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # this port will be forwarded to influx api
  ingress {
    from_port = 8086
    to_port = 8086
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # this port will be forwarded to influx admin panel
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # allow consul ui access
  ingress {
    from_port = 8500
    to_port = 8500
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # rabbitmq management console
  ingress {
    from_port = 15672
    to_port = 15672
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "influxdb" {
  name = "private"
  description = "Disallow access outside vpc"
  vpc_id = "${var.vpc_id}"

  # api access locally
  ingress {
    from_port = 8086
    to_port = 8086
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # ui access locally
  ingress {
    from_port = 8083
    to_port = 8083
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # take input from collectd
  ingress {
    from_port = 25826
    to_port = 25826
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # impersonate graphite
  ingress {
    from_port = 2003
    to_port = 2003
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_instance" "monitor_bastion" {
  instance_type = "t2.micro"
  key_name = "${var.key_name}"
  subnet_id = "${var.subnet_id}"

  ami = "${var.grafana_ami}"
  security_groups = ["${aws_security_group.monitor_bastion.id}",
                     "${var.sg_consul_id}",
                     "${var.sg_public_ssh_id}"]
  associate_public_ip_address = true
  lifecycle { create_before_destroy = true }
}

resource "aws_instance" "influxdb" {
  instance_type = "t2.micro"
  key_name = "${var.key_name}"
  subnet_id = "${var.subnet_id}"

  ami = "${var.influx_ami}"
  security_groups = ["${aws_security_group.influxdb.id}",
                     "${var.sg_consul_id}",
                     "${var.sg_ssh_id}",
                     "${aws_security_group.monitor_bastion.id}"
                    ]
  lifecycle { create_before_destroy = true }
}

output "public_ip" {
  value = "${aws_instance.monitor_bastion.public_ip}"
}
