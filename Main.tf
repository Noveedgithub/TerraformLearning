terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.35.0"
    }
  }
}

provider "aws" {
    region = "us-east-1"
    access_key = "AKIAXPGS7V5A7PZ2HS5S"
    secret_key = "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"
}
#create VPC

resource "aws_vpc" "NoveedVPC" {
  cidr_block = "10.0.0.0/16"
}

#Create Internet gateway

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.NoveedVPC.id

  tags = {
    Name = "NoveedIG"
  }
}

#Create Route Table
resource "aws_route_table" "NoveedRouteTable" {
  vpc_id = aws_vpc.NoveedVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    egress_only_gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Noveed"
  }
}

#Create Subnet

resource "aws_subnet" "Subnet-1" {
vpc_id = aws_vpc.NoveedVPC.id
cidr_block = "10.0.1.0/24"
availability_zone = "us-east-1a"

tags = {
    name = "Subnet"
}
}
#Create AWS Route table

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.Subnet-1.id
  route_table_id = aws_vpc.NoveedVPC.id
}

resource "aws_security_group" "allow_web" {
  name        = "allow_webtraffic"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_route_table.NoveedRouteTable.id

  ingress {
    description      = "Https"
    from_port        = 443
    to_port          = 447
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = [aws_route_table.NoveedRouteTable.id]
  }

    ingress {
    description      = "Http"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = [aws_route_table.NoveedRouteTable.id]
    }

      ingress {
    description      = "ssh"
    from_port        = 2
    to_port          = 2
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = [aws_route_table.NoveedRouteTable.id]
      }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Allow web"
  }
}

#Create AWS Network interface

resource "aws_network_interface" "test" {
  subnet_id       = aws_vpc.NoveedVPC.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]
}

#Elastic IP

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.test.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.gw.id]
}

#AWS Instance

resource "aws_instance" "web_server_instance" {
ami = "ami-08c40ec9ead489470"
instance_type = "t3.micro"
availability_zone = "us-east-1a"
key_name = "noveed"

network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.test.route_table_id
}
}


