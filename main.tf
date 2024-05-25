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

# Subnet
resource "aws_subnet" "subnet-earnest" {
  vpc_id     = aws_vpc.earnest-vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "dev-subnet"
  }
}

resource "aws_security_group" "dg-earnest" {
  name_prefix = "earnest-achayo"
  description = "Example security group"
  vpc_id      = aws_vpc.earnest-vpc.id

  ingress {
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

  tags = {
    Name = "earnest-security-group"
  }
}

# Create an EC2 instance
resource "aws_instance" "earnest-ec2-instance-test" {
  ami                    = "ami-0cc9838aa7ab1dce7"  # Replace with your desired AMI ID
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet-earnest.id
  vpc_security_group_ids = [aws_security_group.dg-earnest.id]

  tags = {
    Name = "dg-earnest-terra-test"
  }
}
