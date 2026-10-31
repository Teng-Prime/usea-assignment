output "swarm_manager_public_ip" {
  value       = aws_instance.swarm_manager.public_ip
  description = "Public IP address of Docker Swarm Manager"
}

output "ecr_repository_url" {
  value       = aws_ecr_repository.app_repo.repository_url
  description = "URL of created Amazon ECR Repository"
}