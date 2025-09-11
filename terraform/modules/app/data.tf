locals {
  default_tags = {
    ManagedBy   = "Terraform"
    Application = var.app_name
    TfEnv       = var.env_name
  }
}

data "aws_ssm_parameter" "kms_arn" {
  name = "/${var.app_name}/common/kms_arn"
}

data "aws_ssm_parameter" "kms_id" {
  name = "/${var.app_name}/common/kms_id"
}

// Shared-GSG -> MyGeotabAPIAdapter -> rds_admin
data "secretsmanager_login" "rds_admin" {
  path = "l3PcA08p731lSh6ht2SPWA"
}

data "secretsmanager_login" "rds_service" {
  path = "OIJwJeIvRv_lziXANk2TDw"
}

data "secretsmanager_field" "rds_service_db" {
  path = "OIJwJeIvRv_lziXANk2TDw/custom_field/database"
}

data "secretsmanager_login" "geotab" {
  path = "1YcOxbb1rBLJkhcf0nww4g"
}

data "secretsmanager_field" "geotab_db" {
  path = "1YcOxbb1rBLJkhcf0nww4g/custom_field/database"
}

// Shared-GSG -> Grafana -> Loki -> BasicAuth
data "secretsmanager_login" "loki_basic" {
  path = "TVNsnRso_U7J_raing91Dw"
}

// Shared-GSG -> Grafana -> Prometheus -> BasicAuth
data "secretsmanager_login" "prometheus_basic" {
  path = "9edLxyQsbIoU5lw7K3m36w"
}
