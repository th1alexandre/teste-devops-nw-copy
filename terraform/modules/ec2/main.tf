data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "this" {
  ami              = data.aws_ami.ubuntu.id
  subnet_id        = var.subnet_id
  instance_type    = var.instance_type
  user_data_base64 = var.user_data
  key_name         = var.key_pair_name

  availability_zone = "sa-east-1a"

  vpc_security_group_ids = [
    var.security_group_id
  ]

  tags = var.tags
}
