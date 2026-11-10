variable "aws_region" {
  description = "AWS region where resources will be provisioned"
  default     = "us-east-1"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance (Ubuntu 24.04 LTS amd64, gp3, Canonical, us-east-1, build 20261108)"
  default     = "ami-08b275ac6cc5dbefb"
}

variable "instance_type" {
  description = "Instance type for the EC2 instance (free tier eligible: 2 vCPU, 8 GiB)"
  default     = "m7i-flex.large"
}

variable "public_key_path" {
  description = "Path to the SSH public key uploaded as the EC2 key pair"
  default     = "~/.ssh/wanderlust-key.pub"
}

variable "volume_size" {
  description = "Root volume size in GiB"
  default     = 30
}
