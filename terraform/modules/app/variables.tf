variable "env_name" {
  type = string
}

variable "app_name" {
  type = string
}

variable "dev_mode" {
  type        = bool
  description = "Enable to disable any type of deletion protection"
}

# VPC
variable "vpc_id" {
  type = string
}

variable "db_subnet_ids" {
  type = list(string)
}

variable "asg_subnet_ids" {
  type = list(string)
}

# RDS
variable "rds_instance_type" {
  type = string
}

variable "rds_snapshot_arn" {
  type    = string
  default = ""
}

variable "rds_engine_version" {
  type = string
}

# EC2
variable "ec2_instance_type" {
  type = string
}

variable "ssh_key_name" {
  type = string
}

variable "ec2_ami_id" {
  type = string
}

variable "build_branch" {
  type        = string
  default     = "main"
  description = "What git branch to checkout before running the build script. Defaults to `main`."
}
