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

module "frontend_ec2" {
  source = "./modules/frontend-ec2"

  project_name          = var.project_name
  public_subnet_id      = module.vpc.public_subnet_id
  frontend_sg_id        = module.security_groups.frontend_sg_id
  instance_profile_name = module.iam.instance_profile_name

  key_name = "AbhayOrg"
}

module "backend_ec2" {
  source = "./modules/backend-ec2"

  project_name          = var.project_name
  public_subnet_id      = module.vpc.public_subnet_id
  backend_sg_id         = module.security_groups.backend_sg_id
  instance_profile_name = module.iam.instance_profile_name
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