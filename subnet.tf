resource "aws_subnet" "public" {
  for_each = local.availability_zones

  vpc_id            = aws_vpc.main.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(local.vpc_cidr, 8, local.az_conf[each.key].index)

  tags = {
    Name = "${local.name}-public-${local.az_conf[each.key].short_name}"
  }
}

resource "aws_subnet" "ecs" {
  for_each = local.availability_zones

  vpc_id            = aws_vpc.main.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(local.vpc_cidr, 8, 10 + local.az_conf[each.key].index)

  tags = {
    Name = "${local.name}-ecs-${local.az_conf[each.key].short_name}"
  }
}

resource "aws_subnet" "rds" {
  for_each = local.availability_zones

  vpc_id            = aws_vpc.main.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(local.vpc_cidr, 8, 20 + local.az_conf[each.key].index)

  tags = {
    Name = "${local.name}-rds-${local.az_conf[each.key].short_name}"
  }
}

resource "aws_subnet" "codebuild" {
  for_each = local.availability_zones

  vpc_id            = aws_vpc.main.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(local.vpc_cidr, 8, 40 + local.az_conf[each.key].index)

  tags = {
    Name = "${local.name}-codebuild-${local.az_conf[each.key].short_name}"
  }
}
