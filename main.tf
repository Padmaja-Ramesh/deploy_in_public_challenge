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

# no bastion host. so these providers not required
# provider "tlf" {}

# provider "local" {}

# ip address isn't required now

# provider "http"{}

# data "http" "myip"{
#     url ="https://ipinfo.io/json"
# }

module "vpc" {
  source = "./vpc"
  region =  var.region
  cidr_block = var.cidr_block
  public_cidr_blocks = var.public_cidr_blocks
  private_cidr_blocks = var.private_cidr_blocks
  rtble_cidr_blocks = var.rtble_cidr_blocks
  app_name = var.app_name


  
}

# resource "aws_vpc" "dip_terraform" {
#   cidr_block       = "10.0.0.0/24"
#   instance_tenancy = "default"

#   tags = {
#     Name = "dip_terraform"
#   }
# }

# resource "aws_subnet" "dip_terraform_public_subnet" {
#   vpc_id     = aws_vpc.dip_terraform.id
#   cidr_block = "10.0.0.0/25"

#   tags = {
#     Name = "dip_terraform_public_subnet"
#   }
# }

# resource "aws_subnet" "dip_terraform_private_subnet" {
#   vpc_id     = aws_vpc.dip_terraform.id
#   cidr_block = "10.0.0.128/25"

#   tags = {
#     Name = "dip_terraform_private_subnet"
#   }
# }

# resource "aws_internet_gateway" "terraform_gw" {
#   vpc_id = aws_vpc.dip_terraform.id

#   tags = {
#     Name = "terraform_gw"
#   }
# }

# resource "aws_route_table" "terraform_public_rtable" {
#   vpc_id = aws_vpc.dip_terraform.id


#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.terraform_gw.id
#   }

#   tags = {
#     Name = "terraform_public_rtable"
#   }
# }

# resource "aws_route_table_association" "terraform_public_rt_asso" {
#   subnet_id      = aws_subnet.dip_terraform_public_subnet.id
#   route_table_id = aws_route_table.terraform_public_rtable.id
# }

# resource "aws_eip" "terraform_eip" {
#   vpc = true
#   depends_on = [aws_internet_gateway.terraform_gw]
# }

# resource "aws_nat_gateway" "terraform_nat_gw"{
#      allocation_id = aws_eip.terraform_eip.id
#   subnet_id     = aws_subnet.dip_terraform_private_subnet.id

#   tags = {
#     Name = "terraform_NATgw"
#   }

#   depends_on = [aws_internet_gateway.terraform_gw]
# }
# resource "aws_route_table" "terraform_private_rtable" {
#   vpc_id = aws_vpc.dip_terraform.id


#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_nat_gateway.terraform_nat_gw.id
#   }

#   tags = {
#     Name = "terraform_private_rtable"
#   }
# }

# resource "aws_route_table_association" "terraform_private_rt_asso" {
#   subnet_id      = aws_subnet.dip_terraform_private_subnet.id
#   route_table_id = aws_route_table.terraform_private_rtable.id
# }


# keys are not required for this week challenge
# resource "tls_private_key" "private_key" {
#   algorithm = "RSA"
#   rsa_bits  = 4096
# }

# resource "aws_key_pair" "key_pair" {
#   key_name   = "dip_terraform_key"
#   public_key = tls_private_key.private_key.public_key_openssh

# }
# resource "local_file" "private_key" {
#   content  = tls_private_key.private_key.private_key_pem
#   filename = "dip_terraform_key.pem"
# }

# public security group isn't required now
# resource "aws_security_group" "terraform_public_sg" {
#   name        = "public_sg"
#   description = "Allow TLS and SSH inbound traffic and all outbound traffic"
#   vpc_id      = module.vpc.vpc_id

#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = [format("%s/32", jsondecode(data.http.myip.response_body).ip)]
#   }

#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "terraform_public_sg"
#   }
# }

resource "aws_security_group" "private_sg" {

    name        = "${var.app_name}-private-sg"
  description = "security group for private"
  vpc_id      = module.vpc.vpc_id
  

  tags = {
    name =  "${var.app_name}-private-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tcp_traffic_from_lb" {
  security_group_id = aws_security_group.private_sg.id
  ip_protocol = "tcp"
  from_port = 3000
  to_port = 3000
  referenced_security_group_id = aws_security_group.lb_sg.id
  
}

resource "aws_vpc_security_group_egress_rule" "allow_tcp_traffic_from_lb" {
  security_group_id = aws_security_group.private_sg.id
  ip_protocol = "-1"
  cidr_ipv4 = "0.0.0.0/0"
  
}

# security group chnaged to aws_vpc_security_group resource

# resource "aws_security_group" "terraform_private_sg" {
#   name        = "private_sg"
#   description = "Allow TLS of Bastion host and SSH inbound traffic of public subnet and all outbound traffic"
#   vpc_id      = module.vpc.vpc_id
# # bastion security group isn't available
#   # ingress {
#   #   from_port   = 22
#   #   to_port     = 22
#   #   protocol    = "tcp"
#   #   security_groups = [aws_security_group.terraform_bastion_sg.id]
#   # }

#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     #we have to allow only traffic through load balancer
#     security_groups = [aws_security_group.lb_sg.id]
#     #cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "terraform_private_sg"
#   }
# }
# bastion host is not required for this weeks challenge
# resource "aws_security_group" "terraform_bastion_sg" {
#   name        = "bastion_sg"
#   description = "Allow  SSH traffic from myip address and  all outbound traffic"
#   vpc_id      = module.vpc.vpc_id

#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = [format("%s/32", jsondecode(data.http.myip.response_body).ip)]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "terraform_bastion_sg"
#   }
# }

# public instance isn't required now
# resource "aws_instance" "app_server_public" {
#   ami           = "ami-060a84cbcb5c14844"
#   instance_type = "t2.micro"

#   associate_public_ip_address = true
#   subnet_id                   = module.vpc.public_subnet_id[0]
#   key_name                    = aws_key_pair.key_pair.key_name
#   vpc_security_group_ids      = [aws_security_group.terraform_public_sg.id]


#   tags = {
#     Name = "TerraformPublicServerInstance"
#   }
# }

resource "aws_instance" "app_server_private" {
  count = 2
  ami           = "ami-060a84cbcb5c14844"
  instance_type = "t2.micro"
  

  associate_public_ip_address = false
  subnet_id                   = module.vpc.private_subnet_ids[count.index]
  # key_name                    = aws_key_pair.key_pair.key_name
  vpc_security_group_ids = [aws_security_group.private_sg.id]

  iam_instance_profile = aws_iam_instance_profile.ec2-profile.name

  # not required for challenge-4
  # user_data = templatefile("./scripts.sh", {instance_id = count.index + 1})

  tags = {
    Name = "${var.app_name}-PrivateServerInstance-${count.index}"
  }
}

# bastion host is not required for this weeks challenge
# resource "aws_instance" "app_server_bastion" {
#   ami           = "ami-060a84cbcb5c14844"
#   instance_type = "t2.micro"

#   associate_public_ip_address = true
#   subnet_id                   = module.vpc.public_subnet_id[0]
#   key_name                    = aws_key_pair.key_pair.key_name
#   vpc_security_group_ids      = [aws_security_group.terraform_bastion_sg.id]


#   tags = {
#     Name = "TerraformBastionServerInstance"
#   }
# }


# iam role and policy setup
resource "aws_iam_role" "ec2-role" {
  name = "${var.app_name}-ec2-role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
})
  
}

resource "aws_iam_role_policy_attachment" "role-policy-attachment" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore", 
    "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
  ])

   role = aws_iam_role.ec2-role.name
  policy_arn = each.value
}

resource "aws_iam_instance_profile" "ec2-profile" {
  name = "${var.app_name}-ec2-profile"
  role = aws_iam_role.ec2-role.name
  
}

# load balancer requires security group,and attachment with ingress rule,egress rule. For listeners and routing =>listers, target group, target group attachment, 

resource "aws_lb"  "load-balancer" {
  name = "${var.app_name}-lb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.lb_sg.id]
  subnets = module.vpc.public_subnet_ids

}
resource "aws_vpc_security_group_ingress_rule" "allow_tcp_traffic" {
  security_group_id = aws_security_group.lb_sg.id
  ip_protocol = "tcp"
  from_port = 80
  to_port = 80
  cidr_ipv4 = "0.0.0.0/0"
  
}

resource "aws_vpc_security_group_egress_rule" "allow_tcp_traffic_lb" {
  security_group_id = aws_security_group.lb_sg.id
  ip_protocol = "-1"
  cidr_ipv4 = "0.0.0.0/0" 
}

resource "aws_security_group" "lb_sg" {

    name        = "${var.app_name}-lb-sg"
  description = "security group for load balancer"
  vpc_id      = module.vpc.vpc_id
  

  tags = {
    name =  "${var.app_name}-lb_sg"
  }
}



resource "aws_lb_target_group" "terraform_tg" {
  name = "${var.app_name}-lb-tg"
  port = 3000
  protocol = "HTTP"
  vpc_id = module.vpc.vpc_id

}

resource "aws_lb_target_group_attachment" "tg_attachment" {
  count = 2
 target_group_arn = aws_lb_target_group.terraform_tg.arn
 target_id = aws_instance.app_server_private[count.index].id
 port = 3000

}

resource "aws_lb_listener" "tg_lister" {
  count = 2
  load_balancer_arn = aws_lb.load-balancer.arn
  port = "80"
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.terraform_tg.arn
  }
}