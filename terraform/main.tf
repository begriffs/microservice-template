### General

provider "aws" {
  region = "${var.region}"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
}

resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.default.id}"
}

### Subnets

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

### Security groups

resource "aws_security_group" "public" {
  vpc_id = "${aws_vpc.default.id}"
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
  vpc_id = "${aws_vpc.default.id}"

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

resource "aws_security_group" "statsd" {
  name = "statsd"
  description = "Open up statsd udp"
  vpc_id = "${aws_vpc.default.id}"

  # api access locally
  ingress {
    from_port = 8125
    to_port = 8125
    protocol = "udp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_security_group" "rabbitmq" {
  name = "rabbitmq"
  description = "Open up rabbitmq server"
  vpc_id = "${aws_vpc.default.id}"

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


### Routers

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

### Instances

resource "aws_instance" "web" {
  instance_type = "t2.micro"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.public.id}"

  ami = "${var.grafana_ami}"
  security_groups = ["${aws_security_group.public.id}",
                     "${aws_security_group.consul.id}",
                     "${aws_security_group.public_ssh.id}"]
  associate_public_ip_address = true
}

resource "aws_instance" "influxdb" {
  instance_type = "t2.micro"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.public.id}"

  ami = "${var.influx_ami}"
  security_groups = ["${aws_security_group.influxdb.id}",
                     "${aws_security_group.consul.id}",
                     "${aws_security_group.ssh.id}",
                     "${aws_security_group.public.id}"
                    ]
}

resource "aws_instance" "statsd" {
  instance_type = "t2.micro"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.private_services.id}"

  ami = "${var.statsd_ami}"
  security_groups = ["${aws_security_group.statsd.id}", "${aws_security_group.consul.id}"]
}

resource "aws_instance" "rabbitmq" {
  instance_type = "t2.micro"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.private_services.id}"

  ami = "${var.rabbitmq_ami}"
  security_groups = ["${aws_security_group.rabbitmq.id}",
                     "${aws_security_group.consul.id}",
                     "${aws_security_group.ssh.id}"]
}

resource "aws_instance" "scraper" {
  instance_type = "t2.micro"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.public.id}"

  ami = "${var.halcyon_ami}"
  security_groups = ["${aws_security_group.public_ssh.id}"]

  connection {
    user = "ec2-user"
    key_file = "~/.ssh/terraform.pem"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo /app/halcyon/halcyon install https://github.com/begriffs/micro-scraper.git"
    ]
  }

  count = "${var.halcyon_workers}"
}

resource "aws_instance" "consul0" {
  instance_type = "t2.micro"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.consul_cluster.id}"
  private_ip = "10.0.1.100"

  ami = "${var.consul_ami}"
  security_groups = ["${aws_security_group.consul.id}"]
}
resource "aws_instance" "consul1" {
  instance_type = "t2.micro"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.consul_cluster.id}"
  private_ip = "10.0.1.101"

  ami = "${var.consul_ami}"
  security_groups = ["${aws_security_group.consul.id}"]
}
resource "aws_instance" "consul2" {
  instance_type = "t2.micro"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.consul_cluster.id}"
  private_ip = "10.0.1.102"

  ami = "${var.consul_ami}"
  security_groups = ["${aws_security_group.consul.id}"]
}
