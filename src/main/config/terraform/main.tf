terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
    }
  }
  backend "s3" {
    bucket = "hangout-tfstate-bucket"
    region = "ap-south-1"
    key = "terraform.tfstate"
    dynamodb_table = "hangout-terraform-lock"
  }
}
provider "aws" {
    region = "ap-south-1"
}
resource "aws_vpc" "hangoutvpc" {
    cidr_block = var.hangoutvpc_cidr
    tags = {
      "Name" = "hangoutvpc"
    }
}
resource "aws_subnet" "hangoutpubsn1" {
  cidr_block = var.hangout_pubsn1
  vpc_id = aws_vpc.hangoutvpc.id
  availability_zone = "ap-south-1a"
  tags = {
    "Name" = "hangoutpubsn1"
  }
}
resource "aws_subnet" "hangoutpubsn2" {
  cidr_block = var.hangout_pubsn2
  vpc_id = aws_vpc.hangoutvpc.id
  tags = {
    "Name" = "hangoutpubsn2"
  }
}
resource "aws_internet_gateway" "hangoutig" {
  vpc_id = aws_vpc.hangoutvpc.id
  tags = {
    "Name" = "hangoutig"
  }
}
resource "aws_route_table" "hangoutigrt" {
  vpc_id = aws_vpc.hangoutvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.hangoutig.id
  }
  tags = {
    "Name" = "hangoutigrt"
  }
}
resource "aws_route_table_association" "hangoutigrtpubsn1assoc" {
  route_table_id = aws_route_table.hangoutigrt.id
  subnet_id = aws_subnet.hangoutpubsn1.id
}
resource "aws_route_table_association" "hangoutigrtpubsn2assoc" {
  route_table_id = aws_route_table.hangoutigrt.id
  subnet_id = aws_subnet.hangoutpubsn2.id
}
resource "aws_security_group" "hangoutec2sg" {
  vpc_id = aws_vpc.hangoutvpc.id
  ingress {
    from_port = "8080"
    to_port = "8080"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = "22"
    to_port = "22"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Name" = "hangoutec2sg"
  }
}
resource "aws_key_pair" "hangoutkp" {
    key_name = "hangoutkp"
    public_key = var.public_key
}
resource "aws_instance" "hangoutec2" {
  subnet_id = aws_subnet.hangoutpubsn1.id
  ami=var.ami
  instance_type = var.instance_type
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.hangoutec2sg.id]
  key_name = aws_key_pair.hangoutkp.key_name
}











