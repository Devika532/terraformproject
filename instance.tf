variable "aws_instance_ami" {}
variable "aws_instance_type" {}

resource "aws_instance" "my_instance" {
  ami                    = var.aws_instance_ami
  instance_type          = var.aws_instance_type
  subnet_id              = aws_subnet.private_subnet_ec2.id
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
}
