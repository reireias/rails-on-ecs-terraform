# NOTE: remove ingress and egress rule in VPC's default SecurityGroup.
# see: https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards-fsbp-controls.html#fsbp-ec2-2
resource "aws_default_security_group" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_default_vpc.default.id
}

resource "aws_security_group" "codebuild" {
  name        = "${local.name}-codebuild"
  description = "For CodeBuild."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name}-codebuild"
  }
}

resource "aws_security_group_rule" "codebuild_egress" {
  description = "Allow all to outbound."
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  # NOTE: Allow egress full open for build
  # tfsec:ignore:AWS007
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.codebuild.id
}

resource "aws_security_group" "vpce_dkr" {
  name        = "${local.name}-vpce-dkr"
  description = "For VPC Endpoint ecr.dkr."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name}-vpce-dkr"
  }
}

resource "aws_security_group_rule" "vpce_dkr_from_codebuild" {
  description              = "Allow HTTPS from Security Group for CodeBuild."
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.codebuild.id
  security_group_id        = aws_security_group.vpce_dkr.id
}
