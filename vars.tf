variable "bucket_name" {
  default = "test-bucket-shebah"
  description = "Name of the S3 bucket"
}

variable "key_name" {
  default = "vm-keypair" # ec2 key pair name of yourKeyName.pem
  description = "Name of the SSH key pair"
}

variable "instance_count" {
    default = 1
    description = "Number of EC2 instances"
}

variable "deployment_name" {
    default = "agent_vm"
}