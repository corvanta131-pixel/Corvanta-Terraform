# Corvanta-Terraform

Terraform configuration for the Corvanta backend on AWS.

The configuration provisions a small, self-contained stack in one AWS account:
a VPC with a public and a private subnet, an internet gateway and route tables,
an S3 bucket, an SQS queue, an IAM role/instance profile for the backend, and a
single Ubuntu EC2 instance in the public subnet with an Elastic IP.

```
corvanta-terraform/
├── main.tf              # root module: provider + module wiring
├── variable.tf          # root input variables
├── locals.tf            # shared naming and tags
├── outputs.tf           # root outputs
├── iam.tf, security.tf, ec2.tf, sqs.tf
│                        # placeholder files: those resources live in modules/
├── terraform.tfvars     # local, git-ignored variable values
├── terraform.tfvars.example
├── ssh.sh               # SSH into the deployed backend
├── tfdeploy.sh          # fmt + validate + plan (never applies)
└── modules/
    ├── network/         # VPC, subnets, IGW, route tables
    ├── iam/             # role, instance profile, S3/SQS policies
    ├── storage/         # S3 bucket, public access block, encryption
    ├── messaging/       # SQS queue
    └── compute/         # security group, key pair, EC2, Elastic IP
```

## Prerequisites

- Terraform >= 1.0 (developed against 1.16.3).
- AWS CLI v2 authenticated against the **target account** (`072718160542`).
  Verify with `aws sts get-caller-identity` and confirm the account ID matches
  the one shown in the AWS Console before creating anything.
- An EC2 SSH key pair on this machine:
  ```
  ssh-keygen -t ed25519 -f ~/.ssh/corvanta-ec2 -C "corvanta-ec2"
  ```
  The private key stays on this machine only. Terraform uploads the matching
  `.pub` file to AWS; the private key is never read by Terraform and must never
  be committed, stored in state, or placed in `terraform.tfvars`.
  To add a passphrase later, run `ssh-keygen -p -f ~/.ssh/corvanta-ec2` in your
  own terminal — never send the passphrase to anyone else.

## Configuration

1. Copy the example variable file and fill in your values:
   ```
   cp terraform.tfvars.example terraform.tfvars
   ```
2. Set `admin_cidr_block` to your current public IPv4 host address in `/32`
   notation:
   ```
   curl -4 https://checkip.amazonaws.com
   ```
   Example: `admin_cidr_block = "102.89.46.236/32"`. The variable rejects
   `0.0.0.0/0` and any CIDR that is not a single `/32` host. `terraform.tfvars`
   is git-ignored; never commit your real IP.

### Variables

| Variable | Default | Description |
| --- | --- | --- |
| `aws_region` | `eu-central-1` | AWS region for the infrastructure |
| `project_name` | `Corvanta` | Project name used in resource names and tags |
| `environment` | `production` | Deployment environment (`production` or `staging`) |
| `backend_instance_type` | `t3.micro` | EC2 instance type for the backend |
| `admin_cidr_block` | *(required)* | IPv4 `/32` host allowed to reach SSH |
| `ssh_public_key_path` | `/home/louis/.ssh/corvanta-ec2.pub` | Public key uploaded as the AWS key pair `corvanta-ec2` |

### Security model

- SSH (TCP 22) is allowed only from `admin_cidr_block`.
- HTTP (TCP 80) and HTTPS (TCP 443) are open to the internet so the backend can
  serve public web traffic.
- The EC2 instance requires IMDSv2 (`http_tokens = "required"`), has an
  encrypted root volume, and runs with an IAM instance profile instead of
  long-lived credentials.
- The S3 bucket blocks all public access and encrypts objects with SSE-S3; the
  SQS queue uses SQS-managed server-side encryption.
- IAM policies are scoped to the created bucket and queue — no wildcards.
- No NAT Gateway is created, so there are no hourly NAT charges.

## Safe validation

These commands only read and format local files; they never touch AWS:

```
terraform fmt -recursive
terraform validate
bash -n ssh.sh
bash -n tfdeploy.sh
```

`terraform validate` confirms the configuration is internally consistent. It
does **not** guarantee that AWS permissions, quotas, account eligibility, SSM
parameter availability, or resource creation will succeed.

## Planning and deployment

`tfdeploy.sh` runs format, validate and `terraform plan`, writes the plan to
`corvanta-review.tfplan`, and stops. It never applies changes.

```
./tfdeploy.sh
terraform show corvanta-review.tfplan
```

Review the plan carefully before applying. Apply deliberately, after the plan
has been reviewed:

```
terraform apply corvanta-review.tfplan
```

> **Before the first plan in a new account:** the `terraform.tfstate` file in
> this directory was created against a previous AWS account
> (`047591775134`) and still contains resources for it. Terraform would try to
> reconcile those resources against the new account, which will fail or propose
> unintended changes. Isolate that state (move it aside, or start from an empty
> state) before running `terraform plan`.

## Connecting to the backend

After the infrastructure is deployed:

```
./ssh.sh
```

The script reads the instance address from the Terraform outputs
(`backend_elastic_ip`, falling back to `backend_public_ip`) and connects as
`ubuntu` with the dedicated key `~/.ssh/corvanta-ec2` and `IdentitiesOnly=yes`.
Host key verification is left at the ssh default, so you are asked to confirm a
new host key the first time. If the instance has not been deployed yet, the
script exits with an explanatory message.

## Outputs

| Output | Description |
| --- | --- |
| `vpc_id` | ID of the Corvanta VPC |
| `backend_instance_id` | ID of the backend EC2 instance |
| `backend_public_ip` | Public IP of the backend instance |
| `backend_private_ip` | Private IP of the backend instance |
| `backend_elastic_ip` | Elastic IP associated with the backend |
| `s3_bucket_name` | Name of the S3 bucket |
| `sqs_queue_url` | URL of the SQS queue |
