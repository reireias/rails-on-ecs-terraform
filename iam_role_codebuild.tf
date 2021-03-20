resource "aws_iam_role" "codebuild" {
  name               = "${local.name}-codebuild"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
}

data "aws_iam_policy_document" "codebuild_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "codebuild" {
  name        = "${local.name}-codebuild"
  description = "For CodeBuild policy."
  policy      = data.aws_iam_policy_document.codebuild.json
}

# see: https://docs.aws.amazon.com/codebuild/latest/userguide/setting-up.html#setting-up-service-role
data "aws_iam_policy_document" "codebuild" {
  statement {
    sid = "CloudWatchLogsPolicy"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["*"]
  }

  statement {
    sid = "S3GetObjectPolicy"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
    ]
    resources = ["*"]
  }

  statement {
    sid = "S3PutObjectPolicy"
    actions = [
      "s3:PutObject",
    ]
    resources = ["*"]
  }

  statement {
    sid = "ECRPullPolicy"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
    ]
    resources = [aws_ecr_repository.rails.arn]
  }

  statement {
    sid = "ECRAuthPolicy"
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = ["*"]
  }

  statement {
    sid = "S3BucketIdentity"
    actions = [
      "s3:GetBucketAcl",
      "s3:GetBucketLocation",
    ]
    resources = ["*"]
  }

  statement {
    sid = "GetSSMParameter"
    actions = [
      "ssm:GetParameters",
    ]
    resources = [
      aws_ssm_parameter.rails_master_key.arn,
    ]
  }

  # NOTE: Launching CodeBuild in a VPC to avoid the Docker Hub rate limit error.
  # see: https://docs.aws.amazon.com/codebuild/latest/userguide/auth-and-access-control-iam-identity-based-access-control.html#customer-managed-policies-example-create-vpc-network-interface
  statement {
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVpcs",
    ]
    resources = ["*"]
  }
  statement {
    actions = [
      "ec2:CreateNetworkInterfacePermission"
    ]
    resources = ["arn:aws:ec2:${local.region}:${local.account_id}:network-interface/*"]
    condition {
      test     = "StringEquals"
      variable = "ec2:Subnet"
      values   = [for _, v in aws_subnet.codebuild : v.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "ec2:AuthorizedService"
      values   = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "codebuild" {
  role       = aws_iam_role.codebuild.name
  policy_arn = aws_iam_policy.codebuild.arn
}
