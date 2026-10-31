variable "aws_region" {
  type        = string
  default     = "ap-southeast-2"
  description = "AWS Region for deployment"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "AWS EC2 instance type for swarm nodes"
}

variable "worker_count" {
  type        = number
  default     = 2
  description = "Number of Docker Swarm worker EC2 instances to provision"
}

variable "key_name" {
  type        = string
  default     = "tenghomework"
  description = "AWS SSH Key pair name"
}

variable "ecr_repo_name" {
  type        = string
  default     = "usea-first-appb"
  description = "Amazon ECR Repository Name"
}
