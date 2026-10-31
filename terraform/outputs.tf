output "swarm_manager_public_ip" {
  value       = aws_instance.swarm_manager.public_ip
  description = "Public IPv4 address of Docker Swarm Manager"
}

output "swarm_worker_public_ips" {
  value       = aws_instance.swarm_workers[*].public_ip
  description = "Public IPv4 addresses of Docker Swarm Worker nodes"
}

output "swarm_manager_private_ip" {
  value       = aws_instance.swarm_manager.private_ip
  description = "Private IP address of Docker Swarm Manager for intra-cluster communication"
}

output "ecr_repository_url" {
  value       = aws_ecr_repository.app_repo.repository_url
  description = "URL of created Amazon ECR Repository"
}

output "security_group_id" {
  value       = aws_security_group.swarm_sg.id
  description = "ID of Swarm Cluster Security Group"
}
