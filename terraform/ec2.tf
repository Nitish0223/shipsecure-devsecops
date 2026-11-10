resource "aws_key_pair" "deployer" {
  key_name   = "wanderlust-key"
  public_key = file(pathexpand(var.public_key_path))
}

resource "aws_default_vpc" "default" {

}

# Your current public IP, so SSH and the admin UIs are not open to the whole internet
data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

locals {
  my_ip_cidr = "${chomp(data.http.my_ip.response_body)}/32"

  # Same ports as the README's master-machine security group.
  # Admin/data ports are limited to your IP; public web ports stay open.
  ingress_rules = [
    { description = "SSH", from = 22, to = 22, cidr = local.my_ip_cidr },
    { description = "SMTP", from = 25, to = 25, cidr = "0.0.0.0/0" },
    { description = "HTTP", from = 80, to = 80, cidr = "0.0.0.0/0" },
    { description = "HTTPS", from = 443, to = 443, cidr = "0.0.0.0/0" },
    { description = "SMTPS", from = 465, to = 465, cidr = "0.0.0.0/0" },
    { description = "Apps, Jenkins 8080, SonarQube 9000", from = 3000, to = 10000, cidr = local.my_ip_cidr },
    { description = "Redis", from = 6379, to = 6379, cidr = local.my_ip_cidr },
    { description = "Kubernetes API", from = 6443, to = 6443, cidr = local.my_ip_cidr },
    { description = "Kubernetes NodePorts (app, ArgoCD)", from = 30000, to = 32767, cidr = "0.0.0.0/0" },
  ]
}

resource "aws_security_group" "allow_user_to_connect" {
  name        = "wanderlust-master-sg"
  description = "Allow user to connect"
  vpc_id      = aws_default_vpc.default.id

  dynamic "ingress" {
    for_each = local.ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.from
      to_port     = ingress.value.to
      protocol    = "tcp"
      cidr_blocks = [ingress.value.cidr]
    }
  }

  egress {
    description = "allow all outgoing traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "wanderlust-master-sg"
  }
}

resource "aws_instance" "testinstance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.allow_user_to_connect.id]

  tags = {
    Name = "wanderlust-master"
  }

  root_block_device {
    volume_size = var.volume_size
    volume_type = "gp3"
  }
}

output "public_ip" {
  value = aws_instance.testinstance.public_ip
}

output "ssh_command" {
  value = "ssh -i ~/.ssh/wanderlust-key ubuntu@${aws_instance.testinstance.public_ip}"
}
