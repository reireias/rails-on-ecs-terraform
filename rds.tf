resource "aws_rds_cluster" "main" {
  cluster_identifier      = "${local.name}-cluster"
  engine                  = "aurora-postgresql"
  engine_version          = "12.4"
  availability_zones      = local.availability_zones
  database_name           = "mydb"
  master_username         = "myuser"
  master_password         = data.aws_kms_secrets.secrets.plaintext["db_password"]
  backup_retention_period = 14
  preferred_backup_window = "18:00-19:00"
  storage_encrypted       = true
  kms_key_id              = aws_kms_key.rds.arn
  db_subnet_group_name    = aws_db_subnet_group.main.id
  vpc_security_group_ids  = [aws_security_group.rds.id]

  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.main.id

  # TODO: debug
  deletion_protection = false
  skip_final_snapshot = true
  lifecycle {
    ignore_changes = [availability_zones]
  }
}

resource "aws_rds_cluster_instance" "main" {
  count = 1 # TODO: 2

  identifier              = "${local.name}-${count.index}"
  cluster_identifier      = aws_rds_cluster.main.id
  instance_class          = "db.t3.medium"
  engine                  = aws_rds_cluster.main.engine
  engine_version          = aws_rds_cluster.main.engine_version
  db_subnet_group_name    = aws_db_subnet_group.main.id
  db_parameter_group_name = aws_db_parameter_group.main.id
  monitoring_role_arn     = aws_iam_role.rds.arn
  monitoring_interval     = 60
}

resource "aws_db_subnet_group" "main" {
  name       = "${local.name}-main"
  subnet_ids = values(aws_subnet.rds)[*].id
}
