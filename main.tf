provider "aws" {
  region = var.aws_region
  access_key = file(var.aws_access_key_file)
  secret_key = file(var.aws_secret_key_file)
}

resource "aws_key_pair" "auth" {
  key_name = var.aws_key_pair_name
  public_key = file(var.public_key_file)
}

resource "aws_instance" "web" {
  ami = var.aws_ec2_ami
  instance_type = var.aws_ec2_type
  key_name = aws_key_pair.auth.id
  associate_public_ip_address = "true"
}
