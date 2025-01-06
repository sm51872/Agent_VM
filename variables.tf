variable "bucket_name" {
  default = "hbc-ops"
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

variable "dac_agent" {
  default = "dacupd.lsstg-2.22.19745.exe"
  description = "DAC agent"
}

variable "user_data" {
  default = "lowside_staging/ls_stage.txt"
  description  = "User data text file"
}

variable "org" {
  default = "Organisation ID"
  description  = "Target"
}

variable "subnet" {
  default = "70"
  description  = "Organisation group ID"
}

variable "defaultID" {
  default = "1"
  description  = "Default ID"
}

variable "Target" {
  default = "default"
  description  = "HA Install Target"
}