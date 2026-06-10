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

  user_data = <<-EOF
#!/bin/bash

exec > /var/log/userdata.log 2>&1

echo "Starting Backend Setup"

apt update -y

apt install docker.io git -y

systemctl start docker
systemctl enable docker

cd /home/ubuntu

git clone https://github.com/abhaysahu403/talentforge-backend.git

cd talentforge-backend

docker build -t talentforge-backend .

docker run -d \
--name talentforge-backend \
-p 5000:5000 \
--restart always \
talentforge-backend

echo "Backend Setup Complete"

EOF
}