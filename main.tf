provider "aws" {
  region = var.aws_region
  access_key = file(var.aws_access_key_file)
  secret_key = file(var.aws_secret_key_file)
}

resource "aws_vpc" "default" {
  cidr_block = "10.1.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
}

resource "aws_subnet" "default" {
  vpc_id = aws_vpc.default.id
  cidr_block = "10.1.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.default.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
}

resource "aws_key_pair" "auth" {
  key_name = var.aws_key_pair_name
  public_key = file(var.public_key_file)
}

resource "aws_instance" "web" {
  ami = var.aws_ec2_ami
  instance_type = var.aws_ec2_type
  key_name = aws_key_pair.auth.id
  subnet_id = aws_subnet.default.id
  associate_public_ip_address = true
}
