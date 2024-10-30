resource "aws_lb" "this" {
  name                       = var.name
  internal                   = false
  load_balancer_type         = "network"
  enable_deletion_protection = false

  subnets = [
    var.subnet_id
  ]

  security_groups = [
    var.security_group_id
  ]

  tags = var.tags
}
