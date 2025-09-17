resource "aws_launch_template" "main" {
  name = "${var.app_name}-${var.env_name}"

  instance_type          = var.ec2_instance_type
  image_id               = var.ec2_ami_id
  update_default_version = true
  vpc_security_group_ids = [aws_security_group.ec2.id]
  key_name               = var.ssh_key_name

  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2.arn
  }

  block_device_mappings {
    # Must exactly match the Amazon Linux AMI device name
    device_name = "/dev/xvda"

    ebs {
      delete_on_termination = true
      volume_size           = 10
      volume_type           = "gp3"
      encrypted             = true
      kms_key_id            = data.aws_ssm_parameter.kms_arn.value
    }
  }

  // This *has* to have no indenting or it won't work
  user_data = base64encode(<<EOF
#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
dnf install -y git
sudo -u ec2-user bash -c 'cd ~; git clone https://github.com/CityOfPhiladelphia/${var.app_name}-iac.git'
sudo -u ec2-user bash -c 'cd ~/${var.app_name}-iac; git checkout ${var.build_branch}; bash server/build.sh ${var.app_name} ${var.env_name}'
EOF
  )

  dynamic "tag_specifications" {
    for_each = toset(["instance", "volume", "network-interface"])
    content {
      resource_type = tag_specifications.key
      tags          = merge(local.default_tags, { Name = "${var.app_name}-${var.env_name}" })
    }
  }

  tags = merge(local.default_tags, { Name = "${var.app_name}-${var.env_name}" })
}

resource "aws_autoscaling_group" "main" {
  name                = "${var.app_name}-${var.env_name}"
  vpc_zone_identifier = var.asg_subnet_ids
  min_size            = 0
  max_size            = 0

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Default"
  }

  # Terraform offloads ASG size
  lifecycle {
    ignore_changes = [min_size, max_size]
  }
}
