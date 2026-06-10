output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_id" {
  value = module.vpc.public_subnet_id
}

output "private_subnet_a_id" {
  value = module.vpc.private_subnet_a_id
}

output "private_subnet_b_id" {
  value = module.vpc.private_subnet_b_id
}

output "frontend_sg_id" {
  value = module.security_groups.frontend_sg_id
}

output "backend_sg_id" {
  value = module.security_groups.backend_sg_id
}

output "rds_sg_id" {
  value = module.security_groups.rds_sg_id
}

output "instance_profile_name" {
  value = module.iam.instance_profile_name
}

output "role_name" {
  value = module.iam.role_name
}

output "frontend_public_ip" {
  value = module.frontend_ec2.frontend_public_ip
}

output "frontend_instance_id" {
  value = module.frontend_ec2.frontend_instance_id
}

output "backend_instance_id" {
  value = module.backend_ec2.backend_instance_id
}

output "backend_public_ip" {
  value = module.backend_ec2.backend_public_ip
}

output "rds_endpoint" {
  value = module.rds.rds_endpoint
}

output "bucket_name" {
  value = module.s3.bucket_name
}