resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr_block

  tags = var.vpc_tags
}

resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.this.id
  cidr_block = var.subnet1_cidr_block

  map_public_ip_on_launch = true
  availability_zone       = "sa-east-1a"

  tags = var.subnet1_tags
}


resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "teste-devops-nw-ig"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "teste-devops-nw-rt-public"
  }
}

resource "aws_route_table_association" "subnet1_association" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.public.id
}
