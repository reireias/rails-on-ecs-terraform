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

resource "aws_route_table" "ecs" {
  for_each = local.availability_zones

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name}-ecs-${local.az_conf[each.key].short_name}"
  }
}

resource "aws_route" "ecs" {
  for_each = local.availability_zones

  route_table_id         = aws_route_table.ecs[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[each.key].id
}

resource "aws_route_table_association" "ecs" {
  for_each = local.availability_zones

  subnet_id      = aws_subnet.ecs[each.key].id
  route_table_id = aws_route_table.ecs[each.key].id
}

resource "aws_vpc_endpoint_route_table_association" "ecs_s3" {
  for_each = local.availability_zones

  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  route_table_id  = aws_route_table.ecs[each.key].id
}

resource "aws_route_table" "rds" {
  for_each = local.availability_zones

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name}-rds-${local.az_conf[each.key].short_name}"
  }
}

resource "aws_route" "rds" {
  for_each = local.availability_zones

  route_table_id         = aws_route_table.rds[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[each.key].id
}

resource "aws_route_table" "codebuild" {
  for_each = local.availability_zones

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name}-codebuild-${local.az_conf[each.key].short_name}"
  }
}

resource "aws_route" "codebuild" {
  for_each = local.availability_zones

  route_table_id         = aws_route_table.codebuild[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[each.key].id
}

resource "aws_route_table_association" "codebuild" {
  for_each = local.availability_zones

  subnet_id      = aws_subnet.codebuild[each.key].id
  route_table_id = aws_route_table.codebuild[each.key].id
}
resource "aws_vpc_endpoint_route_table_association" "codebuild_s3" {
  for_each = local.availability_zones

  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  route_table_id  = aws_route_table.codebuild[each.key].id
}
