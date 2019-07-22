provider "aws" {
  version = "1.13.0"
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}



#-----VPC-------
resource "aws_vpc" "mw_tw_vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags {
    Name = "MW_TW_VPC"
  }
}

#internet gateway

resource "aws_internet_gateway" "mw_tw_internet_gateway" {
  vpc_id = "${aws_vpc.mw_tw_vpc.id}"

  tags {
    Name = "mw_tw_igw"
  }
}

#RT

resource "aws_route_table" "mw_tw_public_rt" {
  vpc_id = "${aws_vpc.mw_tw_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.mw_tw_internet_gateway.id}"
  }

  tags {
    Name = "mw_tw_public_rt"
  }
}

resource "aws_default_route_table" "mw_tw_private_rt" {
  default_route_table_id = "${aws_vpc.mw_tw_vpc.default_route_table_id}"

  tags {
    Name = "mw_tw_private-rt"
  }
}

# Subnets
resource "aws_subnet" "mw_tw_subnet_web1" {
  vpc_id                  = "${aws_vpc.mw_tw_vpc.id}"
  cidr_block              = "${var.cidrs["web1"]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags {
    Name = "mw_tw_subnet_web1"
  }
}

resource "aws_subnet" "mw_tw_subnet_web2" {
  vpc_id                  = "${aws_vpc.mw_tw_vpc.id}"
  cidr_block              = "${var.cidrs["web2"]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[1]}"

  tags {
    Name = "mw_tw_subnet_web2"
  }
}

resource "aws_subnet" "mw_tw_subnet_db" {
  vpc_id                  = "${aws_vpc.mw_tw_vpc.id}"
  cidr_block              = "${var.cidrs["db"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags {
    Name = "mw_tw_subnet_db"
  }
}

resource "aws_subnet" "mw_tw_subnet_elb" {
  vpc_id                  = "${aws_vpc.mw_tw_vpc.id}"
  cidr_block              = "${var.cidrs["elb"]}"
  #map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags {
    Name = "mw_tw_subnet_db"
  }
}

resource "aws_route_table_association" "mw_tw_elb_assoc" {
  subnet_id      = "${aws_subnet.mw_tw_subnet_elb.id}"
  route_table_id = "${aws_route_table.mw_tw_public_rt.id}"
}

resource "aws_route_table_association" "mw_tw_web1_assoc" {
  subnet_id      = "${aws_subnet.mw_tw_subnet_web1.id}"
  route_table_id = "${aws_route_table.mw_tw_public_rt.id}"
}

resource "aws_route_table_association" "mw_tw_web2_assoc" {
  subnet_id      = "${aws_subnet.mw_tw_subnet_web2.id}"
  route_table_id = "${aws_route_table.mw_tw_public_rt.id}"
}
resource "aws_route_table_association" "mw_tw_db_assoc" {
  subnet_id      = "${aws_subnet.mw_tw_subnet_db.id}"
  route_table_id = "${aws_route_table.mw_tw_public_rt.id}"
}

#security groups

resource "aws_security_group" "mw_tw_sg" {
  name        = "mw_tw_sg"
  vpc_id      = "${aws_vpc.mw_tw_vpc.id}"

  #SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #http
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#keypair

resource "tls_private_key" "mw_tw_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "generated_key" {
  key_name   = "${var.keyname}"
  public_key = "${tls_private_key.mw_tw_key.public_key_openssh}"
}


#Launch the instance

resource "aws_instance" "mw_tw_web1" {
  instance_type = "${var.aws_instance_type}"
  ami           = "${var.aws_ami}"

  tags {
    Name = "${lookup(var.aws_tags,"webserver1")}"
    group = "web"
  }
  key_name               = "${aws_key_pair.generated_key.key_name}"
  vpc_security_group_ids = ["${aws_security_group.mw_tw_sg.id}"]
  subnet_id              = "${aws_subnet.mw_tw_subnet_web1.id}"
}
resource "aws_instance" "mw_tw_web2" {
  instance_type = "${var.aws_instance_type}"
  ami           = "${var.aws_ami}"

  tags {
    Name = "${lookup(var.aws_tags,"webserver2")}"
    group = "web"
  }
  key_name               = "${aws_key_pair.generated_key.key_name}"
  vpc_security_group_ids = ["${aws_security_group.mw_tw_sg.id}"]
  subnet_id              = "${aws_subnet.mw_tw_subnet_web2.id}"

}
resource "aws_instance" "mw_tw_dbserver" {
  #depends_on = ["${aws_security_group.mw_sg}"]
  ami           = "${var.aws_ami}"
  instance_type = "${var.aws_instance_type}"
  key_name  = "${aws_key_pair.generated_key.key_name}" 
  vpc_security_group_ids = ["${aws_security_group.mw_tw_sg.id}"]
  subnet_id     = "${aws_subnet.mw_tw_subnet_db.id}"

  tags {
    Name = "${lookup(var.aws_tags,"dbserver")}"
    group = "db"
  }
}
#--------Load balancer-----------------------

resource "aws_elb" "mw_tw_elb" {
  name = "MW-TW-elb"

  subnets = ["${aws_subnet.mw_tw_subnet_web2.id}",
    "${aws_subnet.mw_tw_subnet_web1.id}",
  ]

  security_groups = ["${aws_security_group.mw_tw_sg.id}"]
  instances = ["${aws_instance.mw_tw_web1.id}", "${aws_instance.mw_tw_web2.id}"]
  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = "${var.elb_healthy_threshold}"
    unhealthy_threshold = "${var.elb_unhealthy_threshold}"
    timeout             = "${var.elb_timeout}"
    target              = "TCP:80"
    interval            = "${var.elb_interval}"
  }

  cross_zone_load_balancing = true

  idle_timeout                = 400
  connection_draining_timeout = 400

  tags {
    Name = "mw-tw-elb"
  }
}

output "pem" {
        value = ["${tls_private_key.mw_tw_key.private_key_pem}"]
}

output "address" {
  value = "${aws_elb.mw_tw_elb.dns_name}"
}
