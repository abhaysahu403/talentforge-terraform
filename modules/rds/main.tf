resource "aws_db_subnet_group" "main" {
  name = "${var.project_name}-db-subnet-group"

  subnet_ids = [
    var.private_subnet_a_id,
    var.private_subnet_b_id
  ]

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

resource "aws_db_instance" "mysql" {
  identifier = "${var.project_name}-mysql"

  engine         = "mysql"
  engine_version = "8.0"

  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type       = "gp2"

  db_name  = "talentforge"
  username = "admin"
  password = "TalentForge123!"

  publicly_accessible = false

  vpc_security_group_ids = [
    var.rds_sg_id
  ]

  db_subnet_group_name = aws_db_subnet_group.main.name

  skip_final_snapshot = true

  tags = {
    Name = "${var.project_name}-mysql"
  }
}