variable "aws_region" {
  description = "Where to launch resources."
  default = "us-east-1"
}

variable "aws_access_key_file" {
  description = "What AWS access key to use."
  default = "./auth/aws_access_key"
}

variable "aws_secret_key_file" {
  description = "What AWS secret key to use."
  default = "./auth/aws_secret_key"
}

variable "public_key_file" {
  description = "Public key to use for SSH access."
  default = "./auth/public_key"
}

variable "private_key_file" {
  description = "Private key to use for SSH access."
  default = "./auth/private_key"
}

variable "aws_ec2_ami" {
  description = "What AMI to use."
  default = "ami-04b9e92b5572fa0d1" # Ubuntu 18.04 LTS, us-east-1
  #default = "ami-02cbed67225579b2c" # Ubuntu 18.04 LTS, us-west-2
}

variable "aws_ec2_type" {
  description = "What EC2 instance type to use."
  default = "t2.micro"
}

variable "aws_key_pair_name" {
  description = "Name of the AWS Key Pair to use."
  default = "ba-demo"
}
