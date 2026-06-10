variable "project_name" {
  type = string
}

variable "public_subnet_id" {
  type = string
}

variable "backend_sg_id" {
  type = string
}

variable "instance_profile_name" {
  type = string
}

variable "db_host" {
  type        = string
  description = "RDS database endpoint"
}

variable "db_user" {
  type        = string
  description = "Database username"
  default     = "admin"
}

variable "db_password" {
  type        = string
  description = "Database password"
  sensitive   = true
}

variable "db_name" {
  type        = string
  description = "Database name"
  default     = "talentforge"
}

variable "jwt_secret" {
  type        = string
  description = "JWT secret key for authentication"
  sensitive   = true
}

variable "cors_origin" {
  type        = string
  description = "CORS origin URL for frontend"
}

variable "aws_region" {
  type        = string
  description = "AWS region for S3 and other services"
}

variable "s3_bucket" {
  type        = string
  description = "S3 bucket name for file uploads"
}
