# Declare the data source
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "dip_terraform" {
  cidr_block       = var.cidr_block
  instance_tenancy = "default"

  tags = {
    Name = var.app_name
  }
}

resource "aws_subnet" "dip_terraform_public_subnet" {
    count = 2
  vpc_id     = aws_vpc.dip_terraform.id
  cidr_block = var.public_cidr_blocks[count.index] 
  availability_zone =  data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.app_name}_public_subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "dip_terraform_private_subnet" {
    count = 2
  vpc_id     = aws_vpc.dip_terraform.id
  cidr_block =var.private_cidr_blocks[count.index]
  availability_zone =  data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.app_name}_private_subnet-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "terraform_gw" {
  vpc_id = aws_vpc.dip_terraform.id

  tags = {
    Name = "${var.app_name}_gw"
  }
}

resource "aws_route_table" "terraform_public_rtable" {
  vpc_id = aws_vpc.dip_terraform.id


  route {
    cidr_block =var.rtble_cidr_blocks
    gateway_id = aws_internet_gateway.terraform_gw.id
  }

  tags = {
    Name = "${var.app_name}_public_rtable"
  }
}

resource "aws_route_table_association" "terraform_public_rt_asso" {
    count = 2
  subnet_id      = aws_subnet.dip_terraform_public_subnet[count.index].id
  route_table_id = aws_route_table.terraform_public_rtable.id
}

resource "aws_route_table" "terraform_private_rtable" {
    count = 2
  vpc_id = aws_vpc.dip_terraform.id


  route {
    cidr_block = var.rtble_cidr_blocks
    gateway_id = aws_nat_gateway.terraform_nat_gw[count.index].id
  }

  tags = {
    Name = "${var.app_name}_private_rtable-${count.index + 1}"
  }
}

resource "aws_route_table_association" "terraform_private_rt_asso" {
    count = 2
  subnet_id      = aws_subnet.dip_terraform_private_subnet[count.index].id
  route_table_id = aws_route_table.terraform_private_rtable[count.index].id
}

resource "aws_eip" "terraform_eip" {
  count = 2
  depends_on = [aws_internet_gateway.terraform_gw]
}

resource "aws_nat_gateway" "terraform_nat_gw"{
    count = 2
     allocation_id = aws_eip.terraform_eip[count.index].id
  subnet_id     = aws_subnet.dip_terraform_private_subnet[count.index].id

  tags = {
    Name = "${var.app_name}_NATgw-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.terraform_gw]
}


