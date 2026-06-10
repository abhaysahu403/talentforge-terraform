output "frontend_public_ip" {
  value = aws_instance.frontend.public_ip
}

output "frontend_instance_id" {
  value = aws_instance.frontend.id
}


output "public_ip" {
  value       = aws_instance.frontend.public_ip
  description = "Public IP address of frontend EC2"
}
