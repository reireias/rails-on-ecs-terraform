resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/ecs/${local.name}-app"
  retention_in_days = 1
}

resource "aws_cloudwatch_log_group" "codebuild" {
  name              = "/aws/codebuild/${local.name}-build"
  retention_in_days = 1
}
