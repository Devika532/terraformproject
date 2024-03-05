terraform {
  backend "s3" {
    bucket         = "terraformfile.tf"  
    key            = "terraform.tfstate" 
    region         = "ap-south-1" 
  }
}
#Define the provider
provider "aws" {
  region = "ap-south-1" 

# Define VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Define public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24" 
  availability_zone = "ap-south-1a" 
}

# Create a private subnet
resource "aws_subnet" "private_subnet_ec2" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/24" 
  availability_zone = "ap-south-1a"  
}

resource "aws_ec2_instance_connect_endpoint" "example" {
  subnet_id = aws_subnet.private_subnet_ec2.id
}

resource "aws_subnet" "private_subnet_rds" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.3.0/24" 
  availability_zone = "ap-south-1b" 
}

# Create an internet gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"  
}

resource "aws_nat_gateway" "my_nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
}

resource "aws_route_table" "private_route_table_ec2" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block        = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.my_nat_gateway.id
  }
}

resource "aws_route_table_association" "private_subnet_association_ec2" {
  subnet_id      = aws_subnet.private_subnet_ec2.id
  route_table_id = aws_route_table.private_route_table_ec2.id
  
}

resource "aws_route_table_association" "private_subnet_association_rds" {
  subnet_id      = aws_subnet.private_subnet_rds.id
  route_table_id = aws_vpc.my_vpc.main_route_table_id
}

resource "aws_security_group" "ec2_security_group" {
  name        = "ec2-security-group"
  description = "Security group for EC2 instance"

  vpc_id = aws_vpc.my_vpc.id

  // Define ingress rules
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  // Define egress rules
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a security group for RDS
resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"
  description = "Allow inbound database connections"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "my_instance" {
  ami           = "ami-03bb6d83c60fc5f7c"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_subnet_ec2.id
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
}

# Create a DB subnet group
resource "aws_db_subnet_group" "my_db_subnet_group" {
  name       = "my-db-subnet-group"

 
  subnet_ids = [
  
    aws_subnet.private_subnet_rds.id,
    aws_subnet.private_subnet_ec2.id
    

]
}

# Create an RDS instance
resource "aws_db_instance" "my_rds_instance" {
  identifier             = "my-rds-instance"
  engine                 = "mysql"
  instance_class         = "db.t2.micro"
  allocated_storage      = 20
  storage_type           = "gp2"
  username               = "useradmin"
  password               = "mypassword"
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.my_db_subnet_group.name
  skip_final_snapshot = true
}