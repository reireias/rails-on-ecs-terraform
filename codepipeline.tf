resource "aws_codepipeline" "deploy" {
  name     = "${local.name}-deploy"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn = "arn:aws:codestar-connections:ap-northeast-1:551198746745:connection/2f75cb88-81c2-4edf-b242-561a5de143a0"
        # TODO: use follows
        # ConnectionArn        = aws_codestarconnections_connection.github.arn
        FullRepositoryId     = "reireias/rails-on-ecs"
        BranchName           = "main"
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "BuildRails"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.rails.name
      }
    }
  }
}

# TODO: comment out for debug
# resource "aws_codestarconnections_connection" "github" {
#   name          = "${local.name}-github"
#   provider_type = "GitHub"
# }
