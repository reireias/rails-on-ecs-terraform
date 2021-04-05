resource "aws_cloudwatch_event_rule" "ecr" {
  name        = "${local.name}-ecr-push"
  description = "Push ECR to start CodePipeline."

  event_pattern = jsonencode({
    source      = ["aws.ecr"]
    detail-type = ["ECR Image Action"]
    detail = {
      action-type     = ["PUSH"]
      result          = ["SUCCESS"]
      repository-name = [aws_ecr_repository.rails.name]
      image-tag       = ["latest"]
    }
  })
}

resource "aws_cloudwatch_event_target" "ecr_codepipeline" {
  rule     = aws_cloudwatch_event_rule.ecr.id
  arn      = aws_codepipeline.deploy.arn
  role_arn = aws_iam_role.ecr_event.arn
}
