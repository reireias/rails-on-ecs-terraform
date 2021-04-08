resource "aws_vpc" "main" {
  cidr_block = local.vpc_cidr

  tags = {
    Name = "${local.name}-main"
  }
}

resource "aws_flow_log" "main" {
  log_destination      = aws_s3_bucket.logs.arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.main.id

  # NOTE: Wait creating a policy so that logs can be written.
  depends_on = [aws_s3_bucket_policy.logs]
}

# NOTE: region default VPC
resource "aws_default_vpc" "default" {}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name}-igw"
  }
}

resource "aws_nat_gateway" "nat" {
  for_each = local.availability_zones

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = {
    Name = "${local.name}-nat-${local.az_conf[each.key].short_name}"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = data.aws_vpc_endpoint_service.s3.service_name
  vpc_endpoint_type = "Gateway"

  tags = {
    Name = "${local.name}-s3"
  }
}

data "aws_vpc_endpoint_service" "s3" {
  service      = "s3"
  service_type = "Gateway"
}

resource "aws_vpc_endpoint" "dkr" {
  vpc_id             = aws_vpc.main.id
  service_name       = data.aws_vpc_endpoint_service.dkr.service_name
  vpc_endpoint_type  = "Interface"
  security_group_ids = [aws_security_group.vpce_dkr.id]
  subnet_ids         = concat(values(aws_subnet.ecs)[*].id, values(aws_subnet.codebuild)[*].id)

  tags = {
    Name = "${local.name}-dkr"
  }
}

data "aws_vpc_endpoint_service" "dkr" {
  service = "ecr.dkr"
}
