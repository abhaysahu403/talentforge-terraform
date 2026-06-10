data "aws_ami" "ubuntu" {

  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


resource "aws_instance" "frontend" {

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"

  subnet_id              = var.public_subnet_id

  key_name = var.key_name

  vpc_security_group_ids = [
    var.frontend_sg_id
  ]

  iam_instance_profile = var.instance_profile_name

  associate_public_ip_address = true

  user_data = templatefile("${path.module}/userdata-automated.sh", {
    backend_ip = var.backend_ip
  })

  tags = {
    Name = "${var.project_name}-frontend"
  }
}