variable "project_name" {
}

variable "vpc_tags" {
}

variable "cidr_block" {
}

variable "enable_dns_hostnames" {
  default = true
}

variable "enable_dns_support" {
  default = true
}

variable "common_tags" { 
}

variable "igw_tags" {
}

variable "public_subnet_cidr" {
  type = list
  validation {
    condition = length(var.public_subnet_cidr) == 2
    error_message = "Please provide only two subnet cidrs"
  }
}

variable "private_subnet_cidr" {
  type = list
  validation {
    condition = length(var.private_subnet_cidr) == 2
    error_message = "Please provide only two subnet cidrs"
  }
}

variable "database_subnet_cidr" {
  type = list
  validation {
    condition = length(var.database_subnet_cidr) == 2
    error_message = "Please provide only two subnet cidrs"
  }
}

variable "nat_gateway_tags" {

}

variable "public_route_table_tags" {
  
}

variable "private_route_table_tags" {

}

variable "database_route_table_tags" {
  
}

variable "database_subnet_group_tags" {
  
}

