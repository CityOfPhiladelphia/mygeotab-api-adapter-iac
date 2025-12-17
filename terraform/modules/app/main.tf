terraform {
  required_version = "~> 1.12"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.26.0"
    }
    secretsmanager = {
      source  = "keeper-security/secretsmanager"
      version = "1.1.7"
    }
  }
}

