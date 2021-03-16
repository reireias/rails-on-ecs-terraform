# NOTE: remove ingress and egress rule in VPC's default SecurityGroup.
# see: https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards-fsbp-controls.html#fsbp-ec2-2
resource "aws_default_security_group" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_default_vpc.default.id
}
