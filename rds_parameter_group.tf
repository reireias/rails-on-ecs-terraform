resource "aws_rds_cluster_parameter_group" "main" {
  name        = "${local.name}-cluster-main"
  description = "Cluster Parameter Group"
  family      = "aurora-postgresql12"

  # TODO: configure yourself
}

resource "aws_db_parameter_group" "main" {
  name        = "${local.name}-main"
  description = "Instance Parameter Group"
  family      = "aurora-postgresql12"

  # TODO: configure yourself
}
