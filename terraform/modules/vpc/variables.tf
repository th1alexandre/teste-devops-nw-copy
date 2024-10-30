variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "vpc_tags" {
  description = "A map of tags to add to the VPC"
  type        = map(string)
}

variable "subnet1_cidr_block" {
  description = "The CIDR block for the subnet1"
  type        = string
}

variable "subnet1_tags" {
  description = "A map of tags to add to the subnet1"
  type        = map(string)
}
