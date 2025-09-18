terraform {
  required_version = "~> 1.12"

  cloud {
    organization = "Philadelphia"

    workspaces {
      name = "mygeotab-api-adapter-prod"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    secretsmanager = {
      source  = "keeper-security/secretsmanager"
      version = ">= 1.1.5"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "secretsmanager" {
}

variable "ec2_ami_id" {
  type = string
}

module "app" {
  source = "../../modules/app"

  env_name    = "prod"
  app_name    = "mygeotab-api-adapter"
  app_version = "v3.11.0"
  dev_mode    = true
  # Prod vpc
  vpc_id = "vpc-0ec8b216c381da1e0"
  # Prod subnet private 2 (zone A) then 4 (zone B)
  db_subnet_ids  = ["subnet-024fed84936e66390", "subnet-07ca6947c3468a672"]
  asg_subnet_ids = ["subnet-024fed84936e66390", "subnet-07ca6947c3468a672"]
  # RDS
  rds_snapshot_arn   = "arn:aws:rds:us-east-1:880708401960:snapshot:mygeotab-api-adapter-smaller-size"
  rds_engine_version = "17.6"
  rds_instance_type  = "db.t4g.medium"
  # EC2
  ec2_instance_type = "t3.medium"
  ssh_key_name      = "citygeo"
  ec2_ami_id        = var.ec2_ami_id
  build_branch      = "init"
}
