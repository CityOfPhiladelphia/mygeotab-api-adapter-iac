locals {
  default_tags = {
    ManagedBy   = "Terraform"
    Application = var.app_name
    TfEnv       = "common"
  }
}
