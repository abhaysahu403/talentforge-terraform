data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "backend" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.backend_sg_id]

  iam_instance_profile = var.instance_profile_name

  key_name = "AbhayOrg"

  tags = {
    Name = "${var.project_name}-backend"
  }

  user_data = templatefile("${path.module}/userdata-automated.sh", {
    db_host     = var.db_host
    db_user     = var.db_user
    db_password = var.db_password
    db_name     = var.db_name
    jwt_secret  = var.jwt_secret
    cors_origin = var.cors_origin
    aws_region  = var.aws_region
    s3_bucket   = var.s3_bucket
  })
}