terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# AWS Security Group following Least Privilege
resource "aws_security_group" "swarm_sg" {
  name        = "swarm-cluster-sg"
  description = "Allow SSH, HTTP, and Docker Swarm internal cluster traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 2377
    to_port     = 2377
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance for Swarm Manager
resource "aws_instance" "swarm_manager" {
  ami                    = var.ami_id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.swarm_sg.id]
  key_name               = var.key_name

  tags = {
    Name        = "Swarm-Manager-Group1"
    Environment = "Production"
  }
}

# Amazon ECR Repository
resource "aws_ecr_repository" "app_repo" {
  name                 = var.ecr_repo_name
  image_tag_mutability = "IMMUTABLE"
}