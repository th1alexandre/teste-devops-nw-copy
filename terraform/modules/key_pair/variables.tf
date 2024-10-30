variable "key_pair_name" {
  description = "The name of the key pair"
  type        = string
}

variable "pub_key_path" {
  description = "The path to the public key"
  type        = string
  sensitive   = true
}
