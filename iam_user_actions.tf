# NOTE: IAM User for Image Build and Deploy on GitHub Actions.
resource "aws_iam_user" "actions" {
  name = "${local.name}-actions"
}

resource "aws_iam_access_key" "actions" {
  user = aws_iam_user.actions.name
}

resource "aws_iam_policy" "actions" {
  name   = "${local.name}-actions"
  policy = data.aws_iam_policy_document.actions.json
}

data "aws_iam_policy_document" "actions" {
  statement {
    sid = "ECRPushPullPolicy"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
    ]
    resources = [
      aws_ecr_repository.rails.arn,
    ]
  }

  statement {
    sid = "ECRAuthPolicy"
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = ["*"]
  }

  statement {
    sid = "GetBuildObject"
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "${aws_s3_bucket.build.arn}/*",
    ]
  }

  # see: https://github.com/aws-actions/amazon-ecs-deploy-task-definition#aws-codedeploy-support
  statement {
    sid = "RegisterTaskDefinition"
    actions = [
      "ecs:RegisterTaskDefinition",
    ]
    resources = ["*"]
  }

  statement {
    sid = "PassRolesInTaskDefinition"
    actions = [
      "iam:PassRole",
    ]
    resources = [
      aws_iam_role.ecs.arn,
      aws_iam_role.ecs_task.arn,
    ]
  }

  statement {
    sid = "DeployService"
    actions = [
      "ecs:DescribeServices",
      "codedeploy:GetDeploymentGroup",
      "codedeploy:CreateDeployment",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:RegisterApplicationRevision",
    ]
    resources = [
      aws_ecs_service.app.id,
      "arn:aws:codedeploy:${local.region}:${local.account_id}:application:${aws_codedeploy_app.app.name}",
      "arn:aws:codedeploy:${local.region}:${local.account_id}:deploymentgroup:${aws_codedeploy_app.app.name}/${aws_codedeploy_deployment_group.app.deployment_group_name}",
      "arn:aws:codedeploy:${local.region}:${local.account_id}:deploymentconfig:*",
    ]
  }
}

resource "aws_iam_user_policy_attachment" "actions" {
  user       = aws_iam_user.actions.name
  policy_arn = aws_iam_policy.actions.arn
}
