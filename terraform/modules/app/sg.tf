// RDS security group
resource "aws_security_group" "rds" {
  name        = "${var.app_name}-${var.env_name}-rds"
  description = "SG for RDS"
  vpc_id      = var.vpc_id

  tags = merge(local.default_tags, { Name = "${var.app_name}-${var.env_name}-rds" })
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_app" {
  security_group_id = aws_security_group.rds.id

  description                  = "RDS inbound access from EC2 security group"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.ec2.id
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_phl" {
  security_group_id = aws_security_group.rds.id

  description = "RDS inbound access from City of Philadelphia"
  ip_protocol = "tcp"
  from_port   = 5432
  to_port     = 5432
  cidr_ipv4   = "10.0.0.0/8"
}

// EC2 security group
resource "aws_security_group" "ec2" {
  name        = "${var.app_name}-${var.env_name}-ec2"
  description = "SG for EC2"
  vpc_id      = var.vpc_id

  tags = merge(local.default_tags, { Name = "${var.app_name}-${var.env_name}-ec2" })
}

resource "aws_vpc_security_group_egress_rule" "ec2_outbound_all_to_everywhere" {
  security_group_id = aws_security_group.ec2.id
  description       = "Full outbound access"

  ip_protocol = -1
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "ec2_inbound_ssh_from_phl" {
  security_group_id = aws_security_group.ec2.id
  description       = "Inbound ssh access from City of Philadelphia"

  ip_protocol = "tcp"
  from_port   = 22
  to_port     = 22
  cidr_ipv4   = "10.0.0.0/8"
}
