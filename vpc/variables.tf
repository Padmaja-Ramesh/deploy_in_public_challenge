variable "region"{
    type = string
    description = "region where the vpc is created"
   
}

variable "cidr_block"{
    type = string
    description ="cidr_block for the main vpc"
   
}

variable "public_cidr_blocks"{
    type = list(string)
    description ="cidr_block for the public subnets"
    
}

variable "private_cidr_blocks"{
    type = list(string)
    description ="cidr_block for the private subnets"
   
}

variable "rtble_cidr_blocks"{
    type = string
    description ="cidr_block for the public route table"
    
}

variable "app_name" {
  type = string
  description = "application name"
  
}