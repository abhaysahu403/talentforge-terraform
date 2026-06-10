variable "aws_region" {
  default = "us-east-1"
}

variable "project_name" {
  default = "talentforge"
}

variable "key_name" {
  default = "cloud-nexus-key"
}


# Database Configuration
variable "db_user" {
  description = "Database master username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
  default     = "TalentForge123!"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "talentforge"
}

# Application Configuration
variable "jwt_secret" {
  description = "JWT secret key for token signing"
  type        = string
  sensitive   = true
  default     = "my-super-secret-jwt-key-2026"
}
