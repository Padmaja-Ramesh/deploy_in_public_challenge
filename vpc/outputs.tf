output "availability_zones" {
  value = data.aws_availability_zones.available.names
}

output "vpc_id" {
  value = aws_vpc.dip_terraform.id
}

output "public_subnet_ids" {
  value = aws_subnet.dip_terraform_public_subnet[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.dip_terraform_private_subnet[*].id
}