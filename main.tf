# main.tf - AWS Infrastructure defined using Terraform

# Required Providers and Provider Configuration
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# 1. Data Sources for AMI, VPC, and Subnet
# Data source to find the latest Ubuntu 22.04 LTS AMI (Fixes InvalidAMIID error)
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical's AWS Account ID
}

# Data source to fetch the default VPC ID
data "aws_vpc" "default" {
  default = true
}

# Data source to fetch a single public subnet ID
data "aws_subnet" "selected" {
  vpc_id     = data.aws_vpc.default.id
  filter {
    name   = "mapPublicIpOnLaunch"
    values = ["true"]
  }
  # IMPORTANT: Forces a single result in a specific AZ
  availability_zone = "us-east-1a"
}


# 2. Key Pair (Used for SSH access to EC2)
resource "aws_key_pair" "deployer_key" {
  key_name   = "ci-cd-key"
  # NOTE: Replace the file path if your key is located elsewhere
  public_key = file("~/.ssh/id_rsa.pub") 
}

# 3. Security Group (Allows incoming SSH and HTTP traffic)
resource "aws_security_group" "web_sg" {
  name        = "flask-web-sg"
  description = "Allow SSH and HTTP traffic to Flask app"
  vpc_id      = data.aws_vpc.default.id

  # Ingress (Inbound) Rules
  # Allow SSH from anywhere (0.0.0.0/0)
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTP (Port 80) from anywhere
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress (Outbound) Rule (Allow all outbound traffic)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" 
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Flask-Web-SG"
  }
}

# 4. EC2 Instance
resource "aws_instance" "flask_server" {
  ami           = data.aws_ami.ubuntu.id 
  instance_type = "t3.micro" 
  key_name      = aws_key_pair.deployer_key.key_name
  subnet_id     = data.aws_subnet.selected.id 
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  associate_public_ip_address = true 
  
  # User data script to install Docker on launch
  user_data = <<-EOF
              #!/bin/bash
              # Install Docker
              sudo apt-get update -y
              sudo apt-get install ca-certificates curl gnupg lsb-release -y
              sudo mkdir -m 0755 -p /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
              echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
                $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
              sudo apt-get update -y
              sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
              # Add the default user (ubuntu) to the docker group so we can run docker without sudo
              sudo usermod -aG docker ubuntu
              EOF

  tags = {
    Name = "Flask-CI-CD-Target"
  }
}
