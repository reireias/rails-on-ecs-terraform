resource "aws_subnet" "public" {
  for_each = local.availability_zones

  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet(local.vpc_cidr, 8, local.az_conf[each.key].index)

  tags = {
    Name = "${local.name}-public-${local.az_conf[each.key].short_name}"
  }
}
