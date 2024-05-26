terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.48.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}

resource "aws_ssm_parameter" "test" {
  name  = "/dg/student/key/test/earnest-achayo"
  type  = "String"
  value = "haha"
}

resource "aws_key_pair" "earnest-terra-test_key_pair" {
  key_name   = "earnest-terra-test-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BsXdMsQz1x2cEikKDEY0aIj41qgxMCP/iteneqXSIFZBp5vizPvaoIR3Um9xK7PGoW8giupGn+EPuxIA4cDM4vzOqOkiMPhz5XK0whEjkVzTo4+S0puvDZuwIsdiW9mxhJc7tgBNL0cYlWSYVkz4G/fslNfRPW5mYAM49f4fhtxPb5ok4Q2Lg9dPKVHO/Bgeu5woMc7RY0p1ej6D4CKFE6lymSDJpW0YHX/wqE9+cfEauh7xZcG0q9t2ta6F6fmX0agvpFyZo8aFbXeUBr7osSCJNgvavWbM/06niWrOvYX2xwWdhXmXSrbX8ZbabVohBK41 email@example.com"
}

# Create a VPC
resource "aws_vpc" "earnest-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "dev"
  }
}

# Create IGW
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.earnest-vpc.id
}

# Create Egress-only Internet Gateway
resource "aws_egress_only_internet_gateway" "eigw" {
  vpc_id = aws_vpc.earnest-vpc.id
}

# Create a custom route table
resource "aws_route_table" "dev-route-table" {
  vpc_id = aws_vpc.earnest-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    egress_only_gateway_id = aws_egress_only_internet_gateway.eigw.id
  }

  tags = {
    Name = "Dev"
  }
}

# Subnet
resource "aws_subnet" "subnet-earnest" {
  vpc_id            = aws_vpc.earnest-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "dev-subnet"
  }
}

# AWS route table association
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-earnest.id
  route_table_id = aws_route_table.dev-route-table.id
}

# Create a security group
resource "aws_security_group" "dg-earnest" {
  name_prefix  = "earnest-achayo"
  description  = "Example security group"
  vpc_id       = aws_vpc.earnest-vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-web"
  }
}

# Terraform AWS network interface
resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-earnest.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.dg-earnest.id]
}

# Assign EIP to the NIC
resource "aws_eip" "one" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.gw]
}

# Create Ubuntu server and install/enable apache2
resource "aws_instance" "earnest-ec2-instance-test" {
  ami           = "ami-0cc9838aa7ab1dce7"  # Replace with your desired AMI ID
  instance_type = "t2.micro"
  
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.web-server-nic.id
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo bash -c 'echo Your server is up and running > /var/www/html/index.html'
              EOF

  tags = {
    Name = "earnest-web-server"
  }
}
