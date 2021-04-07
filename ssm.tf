resource "aws_ssm_parameter" "rails_master_key" {
  name        = "/${local.name}/rails_master_key"
  description = "Rails Master Key."
  type        = "SecureString"
  value       = data.aws_kms_secrets.secrets.plaintext["rails_master_key"]
}

resource "aws_ssm_parameter" "database_url" {
  name        = "/${local.name}/database_url"
  description = "DATABASE_URL"
  type        = "SecureString"
  value       = "postgres://myuser:${data.aws_kms_secrets.secrets.plaintext["db_password"]}@${aws_rds_cluster.main.endpoint}:5432/mydb"
}

resource "aws_ssm_parameter" "reader_database_url" {
  name        = "/${local.name}/reader_database_url"
  description = "READER_DATABASE_URL"
  type        = "SecureString"
  value       = "postgres://myuser:${data.aws_kms_secrets.secrets.plaintext["db_password"]}@${aws_rds_cluster.main.reader_endpoint}:5432/mydb"
}
