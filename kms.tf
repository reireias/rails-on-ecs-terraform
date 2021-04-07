resource "aws_kms_key" "terraform" {
  enable_key_rotation = true
}

resource "aws_kms_alias" "terraform" {
  name          = "alias/terraform"
  target_key_id = aws_kms_key.terraform.key_id
}

data "aws_kms_secrets" "secrets" {
  dynamic "secret" {
    for_each = local.secrets

    content {
      name    = secret.key
      payload = secret.value
    }
  }
}

resource "aws_kms_key" "rds" {
  enable_key_rotation = true
}

resource "aws_kms_alias" "rds" {
  name          = "alias/rds"
  target_key_id = aws_kms_key.rds.key_id
}
