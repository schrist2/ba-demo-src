provider "aws" {
  region = var.aws_region
  access_key = file(var.aws_access_key_file)
  secret_key = file(var.aws_secret_key_file)
}

data "aws_availability_zones" "available" {
  state = "available"
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
  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_subnet" "subnet_2" {
  vpc_id = aws_vpc.default.id
  cidr_block = "10.1.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
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

resource "aws_security_group" "allow_private_mysql" {
  name = "allow_private_mysql"
  description = "Allow MySQL connections from the local subnet."
  vpc_id = aws_vpc.default.id

  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = [aws_vpc.default.cidr_block]
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
  
  provisioner "file" {
    source = "./app"
	destination = "~/code"
	
	connection {
      type = "ssh"
	  host = self.public_ip
      user = "ubuntu"
      private_key = file(var.private_key_file)
    }
  }
  
  provisioner "remote-exec" {
    inline = [
		"echo AWS_ACCESS_KEY=${file(var.aws_access_key_file)} | sudo tee --append /etc/environment > /dev/null",
		"echo AWS_SECRET_KEY=${file(var.aws_secret_key_file)} | sudo tee --append /etc/environment > /dev/null",
		"echo S3_BUCKET=${aws_s3_bucket.files.bucket} | sudo tee --append /etc/environment > /dev/null",
		"echo DB_HOST=${aws_db_instance.db.address} | sudo tee --append /etc/environment > /dev/null",
		"echo DB_PORT=${aws_db_instance.db.port} | sudo tee --append /etc/environment > /dev/null",
		"echo DB_USER=${aws_db_instance.db.username} | sudo tee --append /etc/environment > /dev/null",
		"echo DB_PASS=${aws_db_instance.db.password} | sudo tee --append /etc/environment > /dev/null",
		"/bin/bash ~/provision/init.sh"
	]
	connection {
      type = "ssh"
	  host = self.public_ip
      user = "ubuntu"
      private_key = file(var.private_key_file)
    }
  }

  depends_on = [aws_db_instance.db]
}

resource "aws_s3_bucket" "files" {
  acl = "public-read"
}

resource "aws_db_subnet_group" "default" {
  name = "default_db_subnet_group"
  subnet_ids = [aws_subnet.default.id, aws_subnet.subnet_2.id]
}

resource "aws_db_instance" "db" {
  name = "app"
  allocated_storage = 20
  storage_type = "gp2"
  engine = "mysql"
  engine_version = "5.7"
  instance_class = "db.t2.micro"
  username = "root"
  password = "12345678"
  parameter_group_name = "default.mysql5.7"
  db_subnet_group_name = aws_db_subnet_group.default.name
  final_snapshot_identifier = "db-final"
  
  vpc_security_group_ids = [
	aws_security_group.allow_all_outbound.id,
	aws_security_group.allow_private_mysql.id
  ]
}
