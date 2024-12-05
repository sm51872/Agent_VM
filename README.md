# EC2 agent_vm setup

This guide will help you create a EC2 with DAC pre-installed via terraform

## Prerequisities
- Terraform installed on your machine
- An AWS account with appropriate permissions
- AWS CLI installed and configured (if not using cloud9)

## Using Cloud9
Open a cloud9 environment and `git clone` the repository.
To connect to AWS disable the AWS managed temporary credentials in cloud9 (preferences -> AWS Settings)
In the cloud9 terminal following the connecting to AWS instructions.

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

In the terminal navigate to the directory containing the terraform code and run the following commands:

1. Initialise Terraform </br>
`terraform init`

2. Plan the changes </br>
`terraform plan`

3. Apply the changes </br>
`terraform apply`

4. Destroy the resources (when no longer needed) </br>
`terraform destroy`

## Changing variables

Create a `dev_vars.tfvars` or `prod_vars.tfvars` file defining the variables in the `vars.tf` file. </br>
The following variables are defined in `dev_vars.tfvars` or `prod_vars.tfvars` and can be easily changed for the deployment.
```
bucket_name         - Name of bucket containing the dac installer
key_name            - Name of the the key pair
instance_count      - Number of EC2 instances
deployment_name     - Name of the deployment
installation_hint   - Installation hint needed to install DAC
dac_agent           - DAC agent
```
Change the `installation_hint` and `dac_agent` depending on whether it's dev or prod </br>

### Create the deployment (dev/prod)
Create a dev agent using the `dev_vars.tfvars` file, run the following commands
```
terraform plan -var-file=dev_vars.tfvars -out devtfplan.out
terraform apply "devtfplan.out"
```

Create a prod agent using the `prod_vars.tfvars` file, run the following commands
```
terraform plan -var-file=prod_vars.tfvars -out prodtfplan.out
terraform apply "prodtfplan.out"
```

## Accessing the VM via the GUI
Once `terraform apply` has been run. Open the AWS console and navigate to `SSM`.
Naviagate to `fleet manager` (on the left hand menu). 
Under managed nodes the newly created EC2 will appear (this many take some time, be patient).
Tick the box for the EC2, and under account management (top left), click on `Connect with Remote desktop`
Click on `Add connection`, and in the dialog box select the newly created EC2
Under authentication type, chose `Key pair`, leave the Administrator account name as the default `Administrator`
Under key pair content, chose `Paste key pair content` and copy the contents from the .pem file created in cloud9.
Click connect, to start VM and view GUI