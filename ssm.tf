resource "aws_ssm_parameter" "rails_master_key" {
  name        = "/${local.name}/rails_master_key"
  description = "Rails Master Key."
  type        = "SecureString"
  value       = data.aws_kms_secrets.secrets.plaintext["rails_master_key"]
}
