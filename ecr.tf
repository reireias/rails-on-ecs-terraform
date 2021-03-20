resource "aws_ecr_repository" "rails" {
  name = "${local.name}-rails"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}
