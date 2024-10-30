variable "name" {
  description = "The name of the security group"
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to the security group"
  type        = map(string)
}
