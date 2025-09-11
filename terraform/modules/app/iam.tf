resource "aws_iam_policy" "kms" {
  name        = "${var.app_name}-${var.env_name}-kms"
  description = "Enables use of common KMS key"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey",
          "kms:GenerateDataKeyPair*",
        ]
        Effect   = "Allow"
        Resource = data.aws_ssm_parameter.kms_arn.value
      }
    ]
  })

  tags = local.default_tags
}

resource "aws_iam_policy" "ssm" {
  name        = "${var.app_name}-${var.env_name}-ssm"
  description = "Get SSM Parameters"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })

  tags = local.default_tags
}

// EC2 role
resource "aws_iam_role" "ec2" {
  name = "${var.app_name}-${var.env_name}-ec2"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = local.default_tags
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.app_name}-${var.env_name}-ec2"
  role = aws_iam_role.ec2.name
}

resource "aws_iam_role_policy_attachments_exclusive" "ec2" {
  role_name = aws_iam_role.ec2.name
  policy_arns = [
    aws_iam_policy.kms.arn,
    aws_iam_policy.ssm.arn
  ]
}
