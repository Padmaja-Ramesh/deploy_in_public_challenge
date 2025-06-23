variable "region"{
    type = string
    description = "region where the vpc is created"
    default = "us-east-2"
}

variable "cidr_block"{
    type = string
    description ="cidr_block for the main vpc"
    default = "10.0.0.0/24"
}

variable "public_cidr_blocks"{
    type = list(string)
    description ="cidr_block for the public subnets"
    default = [ "10.0.0.0/26" , "10.0.0.64/26"]
}

variable "private_cidr_blocks"{
    type = list(string)
    description ="cidr_block for the private subnets"
    default = [ "10.0.0.128/26", "10.0.0.192/26"]
}

variable "rtble_cidr_blocks"{
    type = string
    description ="cidr_block for the public route table"
    default =  "0.0.0.0/0"
}

variable "app_name" {
  type = string
  description = "application name"
  default = "dip-terraform"
}