terraform {
  required_version = "~> 1.12"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.26.0"
    }
  }

  backend "s3" {
    bucket = "phl-citygeo-terraform-state"
    # CHANGE ME!
    key          = "mygeotab-api-adapter/common"
    region       = "us-east-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = "us-east-1"
}
