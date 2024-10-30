variable "name" {
  description = "The name of the load balancer"
  type        = string
}

variable "subnet_id" {
  description = "The subnet ID to place the load balancer in"
  type        = string
}

variable "security_group_id" {
  description = "The security group ID to use for the load balancer"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to the load balancer"
  type        = map(string)
}
