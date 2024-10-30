module "vpc" {
  source = "./modules/vpc"

  vpc_cidr_block = var.vpc_cidr_block
  vpc_tags = {
    Name       = "teste-devops-nw-vpc"
    managed_by = "terraform"
  }

  subnet1_cidr_block = var.subnet1_cidr_block
  subnet1_tags = {
    Name       = "teste-devops-nw-subnet1"
    managed_by = "terraform"
  }
}

module "ec2_security_group" {
  source = "./modules/security_group"

  name   = "teste-devops-nw-ec2-sg"
  vpc_id = module.vpc.vpc_id
  tags = {
    Name       = "teste-devops-nw-ec2-sg"
    managed_by = "terraform"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ec2_allow_lb" {
  security_group_id            = module.ec2_security_group.security_group_id
  referenced_security_group_id = module.lb_security_group.security_group_id
  from_port                    = 5000
  ip_protocol                  = "tcp"
  to_port                      = 5000

  tags = {
    Name = "Allow ALB Inbound"
  }
}

/*
  GitHub Actions needs to be able to SSH into the EC2 instance to re-deploy the application with new changes.
  This rule allows SSH access from anywhere because Gh Actions (cloud runners) doesn't have a fixed IP/CIDR range.

  A better approach would be to use Gh Actions' self-hosted runners or use larger runners with static IPs.
  And then, allow SSH access only from those IPs (self-hosted or larger runners static IP CIDR ranges).
*/
resource "aws_vpc_security_group_ingress_rule" "ec2_allow_ssh" {
  security_group_id = module.ec2_security_group.security_group_id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22

  tags = {
    Name = "Allow SSH Inbound"
  }
}

module "lb_security_group" {
  source = "./modules/security_group"

  name   = "teste-devops-nw-lb-sg"
  vpc_id = module.vpc.vpc_id
  tags = {
    Name       = "teste-devops-nw-lb-sg"
    managed_by = "terraform"
  }
}

resource "aws_vpc_security_group_ingress_rule" "lb_allow_https" {
  security_group_id = module.lb_security_group.security_group_id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "lb_allow_http" {
  security_group_id = module.lb_security_group.security_group_id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

module "ec2_key_pair" {
  source = "./modules/key_pair"

  key_pair_name = "teste-devops-nw"
  pub_key_path  = pathexpand("${path.module}/.ssh/teste-devops-nw.pub")
}

module "ec2" {
  source = "./modules/ec2"

  instance_type     = "t2.micro"
  subnet_id         = module.vpc.subnet1_id
  security_group_id = module.ec2_security_group.security_group_id
  user_data         = filebase64("${path.module}/scripts/teste-devops-nw.sh")
  key_pair_name     = module.ec2_key_pair.key_pair_name

  tags = {
    Name       = "teste-devops-nw"
    managed_by = "terraform"
  }
}

module "nlb" {
  source = "./modules/load_balancer"

  name              = "teste-devops-nw-nlb"
  subnet_id         = module.vpc.subnet1_id
  security_group_id = module.lb_security_group.security_group_id

  tags = {
    Name       = "teste-devops-nw-nlb"
    managed_by = "terraform"
  }
}

resource "aws_lb_target_group" "ec2_target_group" {
  name     = "teste-devops-nw-tg"
  port     = 5000
  protocol = "TCP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    protocol            = "HTTP"
    port                = "5000"
    path                = "/health"
  }
}

resource "aws_lb_listener" "nlb_listener" {
  load_balancer_arn = module.nlb.arn
  protocol          = "TCP"
  port              = 80

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ec2_target_group.arn
  }
}

resource "aws_lb_target_group_attachment" "my_target_group_attachment" {
  target_group_arn = aws_lb_target_group.ec2_target_group.arn
  target_id        = module.ec2.instance_id
  port             = 5000
}
