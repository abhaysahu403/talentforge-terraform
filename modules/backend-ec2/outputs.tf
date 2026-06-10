output "backend_instance_id" {
  value = aws_instance.backend.id
}

output "backend_public_ip" {
  value = aws_instance.backend.public_ip
}


output "public_ip" {
  value       = aws_instance.backend.public_ip
  description = "Public IP address of backend EC2"
}
