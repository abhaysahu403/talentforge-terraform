output "rds_endpoint" {
  value = aws_db_instance.mysql.endpoint
}

output "rds_identifier" {
  value = aws_db_instance.mysql.id
}


output "db_endpoint" {
  value       = aws_db_instance.mysql.endpoint
  description = "RDS database endpoint"
}
