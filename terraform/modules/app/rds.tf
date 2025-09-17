resource "aws_db_subnet_group" "postgres" {
  name       = "${var.app_name}-${var.env_name}"
  subnet_ids = var.db_subnet_ids

  tags = local.default_tags
}

resource "aws_db_instance" "postgres" {
  identifier            = "${var.app_name}-${var.env_name}"
  allocated_storage     = 500
  max_allocated_storage = 600
  storage_type          = "gp3"
  engine                = "postgres"
  engine_version        = var.rds_engine_version
  db_subnet_group_name  = aws_db_subnet_group.postgres.name
  # Should be empty if restoring a snapshot
  db_name                    = length(var.rds_snapshot_arn) > 0 ? "" : "postgres"
  username                   = data.secretsmanager_login.rds_admin.login
  password                   = data.secretsmanager_login.rds_admin.password
  auto_minor_version_upgrade = true
  storage_encrypted          = true
  kms_key_id                 = data.aws_ssm_parameter.kms_arn.value
  deletion_protection        = !var.dev_mode
  skip_final_snapshot        = var.dev_mode
  instance_class             = var.rds_instance_type
  snapshot_identifier        = var.rds_snapshot_arn

  vpc_security_group_ids = [aws_security_group.rds.id]

  tags = local.default_tags
}
