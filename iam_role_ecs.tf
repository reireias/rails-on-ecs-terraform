resource "aws_iam_role" "ecs" {
  name               = "${local.name}-ecs"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

data "aws_iam_policy_document" "ecs_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "ecs" {
  name        = "${local.name}-ecs"
  description = "For ECS Execution Task policy."
  policy      = data.aws_iam_policy_document.ecs.json
}

data "aws_iam_policy_document" "ecs" {
  # NOTE: For get System Manager Prameter Store
  statement {
    actions = [
      "ssm:GetParameters",
    ]
    resources = [
      aws_ssm_parameter.rails_master_key.arn,
    ]
  }
}

resource "aws_iam_role_policy_attachment" "ecs" {
  role       = aws_iam_role.ecs.name
  policy_arn = aws_iam_policy.ecs.arn
}

resource "aws_iam_role_policy_attachment" "ecs_basic" {
  role       = aws_iam_role.ecs.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
