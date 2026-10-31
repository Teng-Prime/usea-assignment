variable "aws_region" {
  default     = "ap-southeast-2"
  description = "AWS Region for deployment"
}

variable "ami_id" {
  default     = "ami-003a31868351b6a38"
  description = "Ubuntu 22.04 LTS AMI ID"
}

variable "key_name" {
  default     = "swarm-ssh-key"
  description = "AWS SSH Key pair name"
}

variable "ecr_repo_name" {
  default     = "usea-first-appb"
  description = "Amazon ECR Repository Name"
}