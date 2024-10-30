variable "instance_type" {
  description = "The type of instance to start"
  type        = string
}

variable "subnet_id" {
  description = "The subnet ID to launch the instance in"
  type        = string
}

variable "security_group_id" {
  description = "The ID of the security group to associate with the instance"
  type        = string
}

variable "user_data" {
  description = "The user data to provide when launching the instance"
  type        = string
  sensitive   = true
}

variable "key_pair_name" {
  description = "The name of the key pair to use for the instance"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to the EC2 instance"
  type        = map(string)
}
