output "vpc_id" {
  value = aws_vpc.this.id
}

output "subnet1_id" {
  value = aws_subnet.subnet1.id
}
