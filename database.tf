variable "aws_db_instance_engine" {}
variable "aws_db_instance_class" {}
variable "aws_db_instance_allocated_storage" {}
variable "aws_db_instance_storage_type" {}
variable "aws_db_instance_username" {}
variable "aws_db_instance_password" {}

resource "aws_db_subnet_group" "my_db_subnet_group" {
  name       = "my-db-subnet-group"
  subnet_ids = [
    aws_subnet.private_subnet_rds.id,
    aws_subnet.private_subnet_ec2.id
  ]
}

resource "aws_db_instance" "my_rds_instance" {
  identifier             = "my-rds-instance"
  engine                 = var.aws_db_instance_engine
  instance_class         = var.aws_db_instance_class
  allocated_storage      = var.aws_db_instance_allocated_storage
  storage_type           = var.aws_db_instance_storage_type
  username               = var.aws_db_instance_username
  password               = var.aws_db_instance_password
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.my_db_subnet_group.name
  skip_final_snapshot    = true
}
