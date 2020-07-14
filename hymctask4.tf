provider "aws" {
    region ="ap-south-1"
    profile = "lwprofile"
  
}



resource "aws_vpc" "myvpc1" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"

  tags = {
    Name = "pratvpc"
  }
}

resource "aws_security_group" "new_sg" {
  name        = "new_sg"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.myvpc1.id

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name ="secgroup"
  }
}

resource "aws_security_group" "bastion" {
  name        = "bastionsecgrp"
  description = "Allow bastion host"
  vpc_id      = aws_vpc.myvpc1.id

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name ="bastionsecgroup"
  }
}

resource "aws_security_group" "mysqlsg" {
  name        = "mysqlsecgrp"
  description = "Allow mysql"
  vpc_id      = aws_vpc.myvpc1.id

ingress {
    description = "MYSQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.new_sg.id]
  }
  
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name ="mysqlsecgroup"
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.myvpc1.id
  cidr_block = "192.168.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true

   tags = {
    Name = "1stSubnet"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id     = aws_vpc.myvpc1.id
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1b"
  
  tags = {
    Name = "2ndSubnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.myvpc1.id

  tags = {
    Name = "gateway"
  }
}
resource "aws_route_table" "r" {
  vpc_id = aws_vpc.myvpc1.id

route{
  cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.gw.id
  }

   tags = {
    Name = "route_table"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.r.id
}

resource "aws_eip" "nat"{
  vpc = true
}


resource "aws_nat_gateway" "nat_gw"{
  allocation_id = aws_eip.nat.id
  subnet_id = aws_subnet.subnet1.id
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_route_table" "c" {
  vpc_id = aws_vpc.myvpc1.id

route{
  cidr_block = "0.0.0.0/0"
  gateway_id = aws_nat_gateway.nat_gw.id
  }

   tags = {
    Name = "route_table2"
  }
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.c.id
}

resource "aws_instance" "os1" {
  ami           = "ami-0979674e4a8c6ea0c"
  instance_type = "t2.micro"
  key_name = "my_key"
  vpc_security_group_ids =[aws_security_group.new_sg.id]
  subnet_id = aws_subnet.subnet1.id
 

  tags = {
    Name = "wordpress_instance"
  }
}

resource "aws_instance" "os2" {
  ami           = "ami-0732b62d310b80e97"
  instance_type = "t2.micro"
  key_name = "my_key"
  vpc_security_group_ids =[aws_security_group.bastion.id]
  subnet_id = aws_subnet.subnet1.id
 

  tags = {
    Name = "bastionins"
  }
}

resource "aws_instance" "os3" {
  ami           = "ami-08706cb5f68222d09"
  instance_type = "t2.micro"
  key_name = "my_key"
  vpc_security_group_ids =[aws_security_group.mysqlsg.id,aws_security_group.bastion.id]
  subnet_id = aws_subnet.subnet2.id
 

  tags = {
    Name = "mysql_instance"
  }
}

