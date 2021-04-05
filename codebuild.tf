resource "aws_codebuild_project" "build" {
  name          = "${local.name}-build"
  description   = "Create TaskDefinition and run db:migrate"
  build_timeout = 10
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"]
  }

  environment {
    compute_type    = "BUILD_GENERAL1_MEDIUM"
    image           = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.codebuild.name
    }
  }

  source {
    type = "CODEPIPELINE"
    buildspec = templatefile("files/buildspec.yml", {
      ssm_rails_master_key_name = aws_ssm_parameter.rails_master_key.name
      ssm_database_url_name     = aws_ssm_parameter.database_url.name
      account_id                = local.account_id
      bucket                    = aws_s3_bucket.build.bucket
      task_definition_key       = aws_s3_bucket_object.task_definition.key
      appspec_key               = aws_s3_bucket_object.appspec.key
    })
  }

  vpc_config {
    vpc_id             = aws_vpc.main.id
    security_group_ids = [aws_security_group.codebuild.id]
    subnets            = [for _, v in aws_subnet.codebuild : v.id]
  }
}
