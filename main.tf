data "aws_caller_identity" "current" {}

// EC2 IAM role
resource "aws_iam_role" "assume_role_ops" {
  name = "ec2-assume-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action    = "sts:AssumeRole"
      },
      {
        Effect = "Allow"
        Principal = {
          Service = ["scheduler.amazonaws.com"]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

// Policy document
data "aws_iam_policy_document" "policy_doc" {
  statement {
    sid = "AllowDescribeInstances"
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceTypes",
      "ec2:GetSerialConsoleAccessStatus"
    ]

    resources = [
      "*",
    ]
  }

  statement {
    sid = "AllowinstanceBasedSerialConsoleAccess"
    effect = "Allow"
    actions = [
      "ec2-instance-connect:SendSerialConsoleSSHPublicKey",
    ]

    resources = [
      "arn:aws:ec2:ec2:eu-west-2:${data.aws_caller_identity.current.account_id}:instance/*",
    ]
  }
  
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::${var.bucket_name}",
    ]
  }
}

resource "aws_iam_policy" "ops_policy" {
  name   = "ops_policy"
  path   = "/"
  policy = data.aws_iam_policy_document.policy_doc.json
}

// Attach EC2_SSM_Access assume policy to a role
resource "aws_iam_role_policy_attachment" "assume_role_policy_attachment_ops" {
  role       = aws_iam_role.assume_role_ops.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

// Attach S3 assume policy to a role
resource "aws_iam_role_policy_attachment" "s3_policy_attachment_ops" {
  role       = aws_iam_role.assume_role_ops.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

// IAM instance profile
resource "aws_iam_instance_profile" "dev_resources_iam_profile" {
  name = "ec2_profile"
  role = aws_iam_role.assume_role_ops.name
}

// To Generate Private Key
resource "tls_private_key" "rsa_4096" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

// Create Key Pair for Connecting EC2 via SSH
resource "aws_key_pair" "key_pair" {
  key_name   = var.key_name
  public_key = tls_private_key.rsa_4096.public_key_openssh
}

// Save PEM file locally
resource "local_file" "private_key" {
  content  = tls_private_key.rsa_4096.private_key_pem
  filename = var.key_name
}

# Create a security group
resource "aws_security_group" "sg_ec2" {
  name        = "sg_ec2"
  description = "Security group for EC2"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.sg_ec2.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_instance" "windows_vm" {
  ami               = "ami-03275bb9c959be973"
  instance_type     = "t3.micro"
  count             = var.instance_count
  key_name               = aws_key_pair.key_pair.key_name
  vpc_security_group_ids = [aws_security_group.sg_ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.dev_resources_iam_profile.name
  user_data       = "${templatefile(var.user_data, {
    dac_agent = var.dac_agent
    Target = var.Target
    org = var.org
    subnet = var.subnet
    defaultID = var.defaultID
  })}"
 
  tags = {
    Name = "${var.deployment_name}-ec2-${count.index}"
  }
}

resource "aws_iam_role_policy_attachment" "scheduler" {
  policy_arn = aws_iam_policy.scheduler.arn
  role       = aws_iam_role.assume_role_ops.name
}

resource "aws_iam_policy" "scheduler" {
  name = "cron_scheduler_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # allow scheduler to execute the task
        Effect = "Allow",
        Action = [
          "ec2:StopInstances",
          "ec2:StartInstances"
        ]
        # trim :<revision> from arn, to point at the whole task definition and not just one revision
        Resource = ["*",]
      },
    ]
  })
}

resource "aws_scheduler_schedule" "stop_schedule" {
  name       = "stop_instances_schedule"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "cron(0 19 ? * * *)"

  count    = var.instance_count
  
  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:stopInstances"
    role_arn = aws_iam_role.assume_role_ops.arn
    input    = jsonencode({
      InstanceIds = [
        aws_instance.windows_vm[count.index].id
      ]
    })
    retry_policy {
      maximum_retry_attempts = 3
    }
  }
}

resource "aws_scheduler_schedule" "start_schedule" {
  name       = "start_instances_schedule"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "cron(0 8 ? * * *)"

  count    = var.instance_count
  
  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:startInstances"
    role_arn = aws_iam_role.assume_role_ops.arn
    input    = jsonencode({
      InstanceIds = [
        aws_instance.windows_vm[count.index].id
      ]
    })
    retry_policy {
      maximum_retry_attempts = 3
    }
  }
}