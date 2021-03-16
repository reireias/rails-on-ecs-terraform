resource "aws_route_table" "public" {
  for_each = local.availability_zones

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name}-public-${local.az_conf[each.key].short_name}"
  }
}

resource "aws_route" "public" {
  for_each = local.availability_zones

  route_table_id         = aws_route_table.public[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
  for_each = local.availability_zones

  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public[each.key].id
}
