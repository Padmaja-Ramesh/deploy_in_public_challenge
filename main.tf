terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }

    tlf = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }

    http = {
      source  = "hashicorp/http"
      version = "~> 3.5"

    }

  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-2"
}

provider "tlf" {}

provider "local" {}

provider "http"{}

data "http" "myip"{
    url ="https://ipinfo.io/json"
}

resource "aws_vpc" "dip_terraform" {
  cidr_block       = "10.0.0.0/24"
  instance_tenancy = "default"

  tags = {
    Name = "dip_terraform"
  }
}

resource "aws_subnet" "dip_terraform_public_subnet" {
  vpc_id     = aws_vpc.dip_terraform.id
  cidr_block = "10.0.0.0/25"

  tags = {
    Name = "dip_terraform_public_subnet"
  }
}

resource "aws_subnet" "dip_terraform_private_subnet" {
  vpc_id     = aws_vpc.dip_terraform.id
  cidr_block = "10.0.0.128/25"

  tags = {
    Name = "dip_terraform_private_subnet"
  }
}

resource "aws_internet_gateway" "terraform_gw" {
  vpc_id = aws_vpc.dip_terraform.id

  tags = {
    Name = "terraform_gw"
  }
}

resource "aws_route_table" "terraform_public_rtable" {
  vpc_id = aws_vpc.dip_terraform.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform_gw.id
  }

  tags = {
    Name = "terraform_public_rtable"
  }
}

resource "aws_route_table_association" "terraform_public_rt_asso" {
  subnet_id      = aws_subnet.dip_terraform_public_subnet.id
  route_table_id = aws_route_table.terraform_public_rtable.id
}

resource "aws_eip" "terraform_eip" {
  vpc = true
  depends_on = [aws_internet_gateway.terraform_gw]
}

resource "aws_nat_gateway" "terraform_nat_gw"{
     allocation_id = aws_eip.terraform_eip.id
  subnet_id     = aws_subnet.dip_terraform_private_subnet.id

  tags = {
    Name = "terraform_NATgw"
  }

  depends_on = [aws_internet_gateway.terraform_gw]
}
resource "aws_route_table" "terraform_private_rtable" {
  vpc_id = aws_vpc.dip_terraform.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.terraform_nat_gw.id
  }

  tags = {
    Name = "terraform_private_rtable"
  }
}

resource "aws_route_table_association" "terraform_private_rt_asso" {
  subnet_id      = aws_subnet.dip_terraform_private_subnet.id
  route_table_id = aws_route_table.terraform_private_rtable.id
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key_pair" {
  key_name   = "dip_terraform_key"
  public_key = tls_private_key.private_key.public_key_openssh

}
resource "local_file" "private_key" {
  content  = tls_private_key.private_key.private_key_pem
  filename = "dip_terraform_key.pem"
}

resource "aws_security_group" "terraform_public_sg" {
  name        = "public_sg"
  description = "Allow TLS and SSH inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.dip_terraform.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [format("%s/32", jsondecode(data.http.myip.response_body).ip)]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform_public_sg"
  }
}

resource "aws_security_group" "terraform_private_sg" {
  name        = "private_sg"
  description = "Allow TLS of Bastion host and SSH inbound traffic of public subnet and all outbound traffic"
  vpc_id      = aws_vpc.dip_terraform.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.terraform_bastion_sg.id]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/25"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform_private_sg"
  }
}

resource "aws_security_group" "terraform_bastion_sg" {
  name        = "bastion_sg"
  description = "Allow  SSH traffic from myip address and  all outbound traffic"
  vpc_id      = aws_vpc.dip_terraform.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [format("%s/32", jsondecode(data.http.myip.response_body).ip)]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform_bastion_sg"
  }
}

resource "aws_instance" "app_server_public" {
  ami           = "ami-060a84cbcb5c14844"
  instance_type = "t2.micro"

  associate_public_ip_address = true
  subnet_id                   = aws_subnet.dip_terraform_public_subnet.id
  key_name                    = aws_key_pair.key_pair.key_name
  vpc_security_group_ids      = [aws_security_group.terraform_public_sg.id]


  tags = {
    Name = "TerraformPublicServerInstance"
  }
}

resource "aws_instance" "app_server_private" {
  ami           = "ami-060a84cbcb5c14844"
  instance_type = "t2.micro"

  associate_public_ip_address = false
  subnet_id                   = aws_subnet.dip_terraform_private_subnet.id
  key_name                    = aws_key_pair.key_pair.key_name
  vpc_security_group_ids      = [aws_security_group.terraform_private_sg.id]


  tags = {
    Name = "TerraformPrivateServerInstance"
  }
}


resource "aws_instance" "app_server_bastion" {
  ami           = "ami-060a84cbcb5c14844"
  instance_type = "t2.micro"

  associate_public_ip_address = true
  subnet_id                   = aws_subnet.dip_terraform_public_subnet.id
  key_name                    = aws_key_pair.key_pair.key_name
  vpc_security_group_ids      = [aws_security_group.terraform_bastion_sg.id]


  tags = {
    Name = "TerraformBastionServerInstance"
  }
}