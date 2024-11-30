terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "eu-west-2"
}

// create IAM role and associate policies

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
      "ec2:GetSerialConsoleAccessStatus",
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
      "arn:aws:ec2:ec2:eu-west-2:955288011248:instance/${aws_instance.windows_vm.id}",
    ]
  }
  
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::test-bucket-shebah",
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

variable "key_name" {
  default = "vm-keypair" # ec2 key pair name of yourKeyName.pem
  description = "Name of the SSH key pair"
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

# data "template_file" "init" {
#   template = file("file.ps1")
# }

resource "aws_instance" "windows_vm" {
  ami               = "ami-03275bb9c959be973"
  instance_type     = "t3.nano"
  key_name               = aws_key_pair.key_pair.key_name
  vpc_security_group_ids = [aws_security_group.sg_ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.dev_resources_iam_profile.name
  user_data       = <<-EOF
                        <powershell>
                        # Define the path for the test file
                        $testFilePath = "C:/Shebah/user_data_test.txt"
                        
                        # Create the directory if it doesn't exist
                        if (-Not (Test-Path -Path "C:/Shebah")) {
                            New-Item -Path "C:/Shebah" -ItemType Directory
                        }
                        
                        # Create a test file to indicate that the user data script has run
                        New-Item -Path $testFilePath -ItemType File -Force
                        
                        # Write a message to the test file
                        "User data script executed successfully on $(Get-Date)" | Out-File -FilePath $testFilePath
                        </powershell>
                        <persist>true</persist>
                        EOF
  tags = {
    Name = "Shebah-Windows-VM"
  }
}