module "vpc" {
  source = "./modules/vpc"

  project_name          = var.project_name
  vpc_cidr              = "10.0.0.0/16"
  public_subnet_cidr    = "10.0.1.0/24"
  private_subnet_a_cidr = "10.0.10.0/24"
  private_subnet_b_cidr = "10.0.11.0/24"
  availability_zone_a   = "us-east-1a"
  availability_zone_b   = "us-east-1b"
}

module "security_groups" {
  source = "./modules/security-groups"

  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
}

module "iam" {

  source = "./modules/iam"

  project_name = var.project_name
}

module "backend_ec2" {
  source = "./modules/backend-ec2"

  project_name          = var.project_name
  public_subnet_id      = module.vpc.public_subnet_id
  backend_sg_id         = module.security_groups.backend_sg_id
  instance_profile_name = module.iam.instance_profile_name

  # Database configuration
  db_host     = module.rds.db_endpoint
  db_user     = var.db_user
  db_password = var.db_password
  db_name     = var.db_name

  # Application configuration
  jwt_secret  = var.jwt_secret
  cors_origin = "*" # Allow all origins to avoid circular dependency
  aws_region  = var.aws_region
  s3_bucket   = module.s3.bucket_name

  depends_on = [module.rds]
}

module "frontend_ec2" {
  source = "./modules/frontend-ec2"

  project_name          = var.project_name
  public_subnet_id      = module.vpc.public_subnet_id
  frontend_sg_id        = module.security_groups.frontend_sg_id
  instance_profile_name = module.iam.instance_profile_name
  backend_ip            = module.backend_ec2.public_ip

  key_name = "AbhayOrg"

  depends_on = [module.backend_ec2]
}

module "rds" {
  source = "./modules/rds"

  project_name        = var.project_name
  private_subnet_a_id = module.vpc.private_subnet_a_id
  private_subnet_b_id = module.vpc.private_subnet_b_id
  rds_sg_id           = module.security_groups.rds_sg_id
}

module "s3" {
  source = "./modules/s3"

  project_name = var.project_name
}