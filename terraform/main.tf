terraform {
  required_version = ">= 1.0.0"
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

# Dynamic AMI lookup for Ubuntu 22.04 LTS (HVM:ebs-ssd)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group following Least-Privilege Architecture
resource "aws_security_group" "swarm_sg" {
  name        = "swarm-cluster-sg"
  description = "Least privilege SG: SSH/HTTP ingress and Swarm intra-cluster traffic"

  # SSH for remote management
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Public HTTP application traffic
  ingress {
    description = "Public HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Public HTTPS traffic
  ingress {
    description = "Public HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Docker Swarm cluster management (TCP 2377) - Intra-cluster only
  ingress {
    description = "Docker Swarm cluster management"
    from_port   = 2377
    to_port     = 2377
    protocol    = "tcp"
    self        = true
  }

  # Docker Swarm node communication (TCP/UDP 7946) - Intra-cluster only
  ingress {
    description = "Docker Swarm node discovery TCP"
    from_port   = 7946
    to_port     = 7946
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Docker Swarm node discovery UDP"
    from_port   = 7946
    to_port     = 7946
    protocol    = "udp"
    self        = true
  }

  # Docker Swarm overlay network traffic (UDP 4789) - Intra-cluster only
  ingress {
    description = "Docker Swarm overlay network VXLAN"
    from_port   = 4789
    to_port     = 4789
    protocol    = "udp"
    self        = true
  }

  # Outbound internet access for package updates and image pulling
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "swarm-cluster-sg"
    Environment = "Production"
    Project     = "USEA-Student-Portal"
  }
}

# EC2 Instance for Docker Swarm Manager
resource "aws_instance" "swarm_manager" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.swarm_sg.id]
  key_name               = var.key_name

  tags = {
    Name        = "Swarm-Manager-Group1"
    Role        = "Swarm-Manager"
    Environment = "Production"
    Project     = "USEA-Student-Portal"
    ManagedBy   = "Terraform"
  }
}

# EC2 Instances for Docker Swarm Workers (Cluster Formed with 1 Manager + 2 Workers)
resource "aws_instance" "swarm_workers" {
  count                  = var.worker_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.swarm_sg.id]
  key_name               = var.key_name

  tags = {
    Name        = "Swarm-Worker-${count.index + 1}-Group1"
    Role        = "Swarm-Worker"
    Environment = "Production"
    Project     = "USEA-Student-Portal"
    ManagedBy   = "Terraform"
  }
}

# Amazon ECR Repository with Immutable Tags and Vulnerability Scanning
resource "aws_ecr_repository" "app_repo" {
  name                 = var.ecr_repo_name
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = var.ecr_repo_name
    Environment = "Production"
    Project     = "USEA-Student-Portal"
  }
}
