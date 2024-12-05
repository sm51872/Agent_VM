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

variable "installation_hint" {
  default = "hbd24:user:default:1010.70.1.ff:bdd58f"
  description = "Installation hint needed to install DAC"
}

variable "dac_agent" {
  default = "dacupd.lsstg-2.22.19745.exe"
  description = "DAC agent"
}