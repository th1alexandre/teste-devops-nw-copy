output "instance_id" {
  value = aws_instance.this.id
}

output "ip_address" {
  value = aws_instance.this.public_ip
}
