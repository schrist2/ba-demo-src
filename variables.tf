variable "aws_region" {
  description = "Where to launch resources."
  default     = "eu-central-1" # EU Frankfurt
}

variable "aws_ec2_ami" {
  description = "What AMI to use."
  default = "ami-0f71209b1289bf95c" # Ubuntu 18.04 LTS
}

variable "aws_ec2_type" {
  description = "What EC2 instance type to use."
  default = "t2.micro"
}
