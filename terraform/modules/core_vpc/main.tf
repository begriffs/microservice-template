variable "consul_cluster_size" {
  default="3"
}

variable "key_name" { }
variable "consul_ami" { }

resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_subnet" "public" {
  vpc_id = "${aws_vpc.default.id}"

  cidr_block = "10.0.0.0/24"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "consul_cluster" {
  vpc_id = "${aws_vpc.default.id}"

  cidr_block = "10.0.1.0/24"
}

resource "aws_subnet" "private_services" {
  vpc_id = "${aws_vpc.default.id}"

  cidr_block = "10.0.2.0/24"
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.default.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
}

resource "aws_route_table_association" "dmz" {
  subnet_id = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_security_group" "consul" {
  name = "consul"
  description = "Consul internal traffic + maintenance."
  vpc_id = "${aws_vpc.default.id}"

  ingress {
    from_port = 53
    to_port = 53
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  ingress {
    from_port = 53
    to_port = 53
    protocol = "udp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  ingress {
    from_port = 8300
    to_port = 8302
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  ingress {
    from_port = 8301
    to_port = 8302
    protocol = "udp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  ingress {
    from_port = 8400
    to_port = 8400
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  ingress {
    from_port = 8500
    to_port = 8500
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_security_group" "ssh" {
  name = "ssh"
  description = "Local ssh access"
  vpc_id = "${aws_vpc.default.id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_security_group" "public_ssh" {
  name = "public_ssh"
  description = "Public ssh access"
  vpc_id = "${aws_vpc.default.id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/0"]
  }
}

variable "consul_instance_ips" {
  default = {
    "0" = "10.0.1.100"
    "1" = "10.0.1.101"
    "2" = "10.0.1.102"
    "3" = "10.0.1.103"
    "4" = "10.0.1.104"
    "5" = "10.0.1.105"
    "6" = "10.0.1.106"
  }
}

resource "aws_instance" "consul" {
  instance_type = "t2.micro"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.consul_cluster.id}"
  private_ip = "${lookup(var.consul_instance_ips, count.index)}"

  ami = "${var.consul_ami}"
  security_groups = ["${aws_security_group.consul.id}"]

  lifecycle { create_before_destroy = true }

  count = "${var.consul_cluster_size}"
}

output "id" {
  value = "${aws_vpc.default.id}"
}

output "sg_public_ssh_id" {
  value = "${aws_security_group.public_ssh.id}"
}
output "sg_ssh_id" {
  value = "${aws_security_group.ssh.id}"
}
output "sg_consul_id" {
  value = "${aws_security_group.consul.id}"
}
output "private_subnet_id" {
  value = "${aws_subnet.private_services.id}"
}
output "public_subnet_id" {
  value = "${aws_subnet.public.id}"
}
