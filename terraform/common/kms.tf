data "aws_caller_identity" "current" {}

resource "aws_kms_key" "common" {
  description = "${var.app_name} common"
  key_usage   = "ENCRYPT_DECRYPT"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*"
        Resource = "*"
      },
      {
        // Allow ASG to use CMK
        // https://docs.aws.amazon.com/autoscaling/ec2/userguide/key-policy-requirements-EBS-encryption.html#policy-example-cmk-access
        Sid    = "Allow service-linked role use of the customer managed key"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        // Allow ASG to use CMK
        // https://docs.aws.amazon.com/autoscaling/ec2/userguide/key-policy-requirements-EBS-encryption.html#policy-example-cmk-access
        Sid    = "Allow attachment of persistent resources"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
        }
        Action = [
          "kms:CreateGrant"
        ]
        Resource = "*"
        Condition = {
          Bool = {
            "kms:GrantIsForAWSResource" = true
          }
        }
      }
    ]
  })

  tags = local.default_tags
}

resource "aws_kms_alias" "common" {
  name          = "alias/${var.app_name}"
  target_key_id = aws_kms_key.common.key_id
}

resource "aws_ssm_parameter" "kms_arn" {
  name  = "/${var.app_name}/common/kms_arn"
  value = aws_kms_key.common.arn
  type  = "String"
}

resource "aws_ssm_parameter" "kms_id" {
  name  = "/${var.app_name}/common/kms_id"
  value = aws_kms_key.common.key_id
  type  = "String"
}
