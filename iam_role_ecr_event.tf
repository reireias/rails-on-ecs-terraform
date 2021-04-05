resource "aws_iam_role" "ecr_event" {
  name               = "${local.name}-ecr-event"
  assume_role_policy = data.aws_iam_policy_document.ecr_event_assume.json
}

data "aws_iam_policy_document" "ecr_event_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "ecr_event" {
  name        = "${local.name}-ecr-event"
  description = "For ECS Execution Task policy."
  policy      = data.aws_iam_policy_document.ecr_event.json
}

data "aws_iam_policy_document" "ecr_event" {
  statement {
    actions = [
      "codepipeline:StartPipelineExecution",
    ]
    resources = [
      aws_codepipeline.deploy.arn,
    ]
  }
}

resource "aws_iam_role_policy_attachment" "ecr_event" {
  role       = aws_iam_role.ecr_event.name
  policy_arn = aws_iam_policy.ecr_event.arn
}
