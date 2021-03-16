data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

locals {
  name = "reireias2021"

  # availability_zones = toset(data.aws_availability_zones.available.names)
  # NOTE: for debug with low cost
  availability_zones = toset(["ap-northeast-1a"])

  az_conf = {
    "ap-northeast-1a" = {
      index      = 1
      short_name = "1a"
    }
    "ap-northeast-1c" = {
      index      = 2
      short_name = "1c"
    }
    "ap-northeast-1d" = {
      index      = 3
      short_name = "1d"
    }
  }

  vpc_cidr = "10.0.0.0/16"
}
