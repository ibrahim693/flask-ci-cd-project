# outputs.tf - Outputs definition

output "public_ip" {
  description = "Public IP address of the Flask EC2 instance"
  value       = aws_instance.flask_server.public_ip
}

output "ssh_user" {
  description = "The default SSH username for the Ubuntu instance"
  value       = "ubuntu"
}