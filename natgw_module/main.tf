# create natgw_eip:
resource "aws_eip" "natgw_eip" {
  vpc = true

  tags = {
    Name = var.natgw_eip_tag
  }
}

# create natgw:
resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.natgw_eip.id
  subnet_id     = var.natgw_subnet_id
  depends_on    = [aws_eip.natgw_eip]

  tags = {
    Name = var.natgw_tag
  }
}
