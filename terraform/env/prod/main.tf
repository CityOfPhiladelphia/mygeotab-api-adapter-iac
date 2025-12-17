terraform {
  required_version = "~> 1.12"

  backend "s3" {
    bucket = "phl-citygeo-terraform-state"
    # CHANGE ME!
    key          = "mygeotab-api-adapter/prod"
    region       = "us-east-1"
    use_lockfile = true
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

  assume_role {
    role_arn     = "arn:aws:iam::880708401960:role/TFRole"
    session_name = "tf"
  }
}

provider "secretsmanager" {
}

module "app" {
  source = "../../modules/app"

  env_name = "prod"
  app_name = "mygeotab-api-adapter"
  # renovate: datasource=github-releases depName=Geotab/mygeotab-api-adapter
  app_version = "v3.14.0"
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
  # Note: AMI is hardcoded to Kernel 6.12. Make note to occasionally update that manually
  # amiFilter=[{"Name":"owner-id","Values":["137112412989"]},{"Name":"name","Values":["al2023-ami-2023*-kernel-6.12-x86_64"]},{"Name":"architecture","Values":["x86_64"]},{"Name":"virtualization-type","Values":["hvm"]}]
  # currentImageName=al2023-ami-2023.9.20251117.1-kernel-6.12-x86_64
  ec2_ami_id   = "ami-0f00d706c4a80fd93"
  build_branch = "main"
}
