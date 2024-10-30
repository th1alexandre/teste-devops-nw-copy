output "lb_dns" {
  value = module.nlb.dns_name
}

output "ec2_ip_address" {
  value = module.ec2.ip_address
}
