resource "aws_s3_bucket" "build" {
  bucket = "${local.name}.build"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  logging {
    target_bucket = aws_s3_bucket.logs.id
    target_prefix = "s3/${local.name}.build/"
  }

  force_destroy = true
}

resource "aws_s3_bucket_policy" "build" {
  bucket = aws_s3_bucket.build.id
  policy = data.aws_iam_policy_document.build_bucket.json
}

data "aws_iam_policy_document" "build_bucket" {
  # see: https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards-fsbp-controls.html#fsbp-s3-5
  statement {
    sid    = "AllowSSLRequestsOnly"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.build.arn,
      "${aws_s3_bucket.build.arn}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_object" "task_definition_app" {
  bucket = aws_s3_bucket.build.id
  key    = "task_definition_app.json"
  content = templatefile("files/task_definition_app.json", {
    family                    = aws_ecs_task_definition.app.family
    task_role_arn             = aws_iam_role.ecs_task.arn
    execution_role_arn        = aws_iam_role.ecs.arn
    ssm_rails_master_key_name = aws_ssm_parameter.rails_master_key.name
    log_group                 = aws_cloudwatch_log_group.app.name
    region                    = local.region
  })
}

resource "aws_s3_bucket_object" "app_spec" {
  bucket  = aws_s3_bucket.build.id
  key     = "appspec.yml"
  content = file("files/appspec.yml")
}
