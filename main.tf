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

resource "aws_security_group" "allow_all_outbound" {
  name = "allow_all_outbound"
  description = "Allow all outgoing traffic."
  vpc_id = aws_vpc.default.id

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_web" {
  name = "allow_web"
  description = "Allow HTTPS and HTTP traffic from and to everywhere."
  vpc_id = aws_vpc.default.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_ssh" {
  name = "allow_ssh"
  description = "Allow SSH from and to everywhere."
  vpc_id = aws_vpc.default.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  ami = var.aws_ec2_ami
  instance_type = var.aws_ec2_type
  associate_public_ip_address = true
  
  key_name = aws_key_pair.auth.id
  
  subnet_id = aws_subnet.default.id
  
  vpc_security_group_ids = [
    aws_security_group.allow_all_outbound.id,
    aws_security_group.allow_web.id,
	aws_security_group.allow_ssh.id
  ]
  
  provisioner "file" {
    source = "./provision"
	destination = "~/provision"
	
	connection {
      type = "ssh"
	  host = self.public_ip
      user = "ubuntu"
      private_key = file(var.private_key_file)
    }
  }
  
  provisioner "remote-exec" {
    inline = ["/bin/bash ~/provision/init.sh"]
	connection {
      type = "ssh"
	  host = self.public_ip
      user = "ubuntu"
      private_key = file(var.private_key_file)
    }
  }

  #user_data = "/bin/bash ~/provision/init.sh"
}

resource "aws_s3_bucket" "static_content" {
  bucket = "static_content"
  acl = "public-read"
}
