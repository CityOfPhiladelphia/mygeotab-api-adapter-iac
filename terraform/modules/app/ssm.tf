resource "aws_ssm_parameter" "rds_service_pw" {
  name   = "/${var.app_name}/${var.env_name}/rds_service_pw"
  value  = data.secretsmanager_login.rds_service.password
  type   = "SecureString"
  key_id = data.aws_ssm_parameter.kms_id.value
}

resource "aws_ssm_parameter" "rds_service_user" {
  name   = "/${var.app_name}/${var.env_name}/rds_service_user"
  value  = data.secretsmanager_login.rds_service.login
  type   = "SecureString"
  key_id = data.aws_ssm_parameter.kms_id.value
}

resource "aws_ssm_parameter" "rds_host" {
  name  = "/${var.app_name}/${var.env_name}/rds_host"
  value = aws_db_instance.postgres.endpoint
  type  = "String"
}

resource "aws_ssm_parameter" "rds_service_db_name" {
  name  = "/${var.app_name}/${var.env_name}/rds_service_db_name"
  value = data.secretsmanager_field.rds_service_db.value
  type  = "String"
}

resource "aws_ssm_parameter" "geotab_user" {
  name   = "/${var.app_name}/${var.env_name}/geotab_user"
  value  = data.secretsmanager_login.geotab.login
  type   = "SecureString"
  key_id = data.aws_ssm_parameter.kms_id.value
}

resource "aws_ssm_parameter" "geotab_pw" {
  name   = "/${var.app_name}/${var.env_name}/geotab_pw"
  value  = data.secretsmanager_login.geotab.password
  type   = "SecureString"
  key_id = data.aws_ssm_parameter.kms_id.value
}

resource "aws_ssm_parameter" "geotab_db" {
  name  = "/${var.app_name}/${var.env_name}/geotab_db"
  value = data.secretsmanager_field.geotab_db.value
  type  = "String"
}

resource "aws_ssm_parameter" "loki_pw" {
  name   = "/${var.app_name}/${var.env_name}/loki_pw"
  value  = data.secretsmanager_login.loki_basic.password
  type   = "SecureString"
  key_id = data.aws_ssm_parameter.kms_id.value
}

resource "aws_ssm_parameter" "loki_user" {
  name   = "/${var.app_name}/${var.env_name}/loki_user"
  value  = data.secretsmanager_login.loki_basic.login
  type   = "SecureString"
  key_id = data.aws_ssm_parameter.kms_id.value
}

resource "aws_ssm_parameter" "prometheus_pw" {
  name   = "/${var.app_name}/${var.env_name}/prometheus_pw"
  value  = data.secretsmanager_login.prometheus_basic.password
  type   = "SecureString"
  key_id = data.aws_ssm_parameter.kms_id.value
}

resource "aws_ssm_parameter" "prometheus_user" {
  name   = "/${var.app_name}/${var.env_name}/prometheus_user"
  value  = data.secretsmanager_login.prometheus_basic.login
  type   = "SecureString"
  key_id = data.aws_ssm_parameter.kms_id.value
}
