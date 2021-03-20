resource "aws_cloudwatch_log_group" "codebuild" {
  name              = "/aws/codebuild/${local.name}-build-rails"
  retention_in_days = 1
}
