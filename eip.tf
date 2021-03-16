resource "aws_eip" "nat" {
  for_each = local.availability_zones

  vpc = true
}
