# EC2 agent_vm setup

This guide will help you create a EC2 with DAC pre-installed via terraform

## Prerequisities
- Terraform installed on your machine
- An AWS account with appropriate permissions
- AWS CLI installed and configured (if not using cloud9)

## Connecting to AWS
To connect to your AWS account, you need to set up your AWS credentials. 
Terraform will use these credentials to manage your AWS resources.

### Using environment variables
Copy the logon command from the hosting portal

Run the logon command in the terminal.
Run the following commands in the termimal:

```
export AWS_DEFAULT_REGION=eu-west-2
export AWS_ACCESS_KEY_ID={access-key-ID}
export AWS_SECRET_ACCESS_KEY={secret-access-key}
export AWS_SESSION_TOKEN={session-token}
```
## Creating an EC2 via terraform

Navigate to the directory containing the terraform code and run the following commands:

1. Initialise Terraform
`terraform init`

2. Plan the changes
`terraform plan`

3. Apply the changes
`terraform apply`

4. Destroy the resources (when no longer needed)
`terraform destroy`