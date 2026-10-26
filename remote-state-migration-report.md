# Corvanta — Terraform Stage 5: Remote State and Locking Report

## Installed Versions

| Component | Version |
|-----------|---------|
| Terraform | 1.16.3 (out of date; latest is 1.17.0) |
| AWS Provider | 6.68.0 (from .terraform.lock.hcl) |

**Terraform 1.16.x supports the S3 backend with state locking via DynamoDB.** It does NOT use native S3 lockfiles (object-level locking); that feature requires Terraform 1.10+ with the `use_lockfile` S3 backend option, but DynamoDB-based locking is the standard and well-tested mechanism for S3 backend.

## Current State & Backend Configuration

| Item | Value |
|------|-------|
| Backend type | **Local** (no `backend` block in any .tf file) |
| State file | `terraform.tfstate` (serial 31) |
| State backup | `terraform.tfstate.backup` (serial 29) |
| Lock file | None (local state doesn't lock) |
| Lineage | `f5039dff-dadb-cb6a-6629-31e381479cf7` |
| AWS account | `072718160542` (corvanta-admin profile) |
| AWS region | `eu-central-1` |
| Resources tracked | 19 resources across 5 modules |

## Existing S3 Application Bucket Analysis

| Property | Value |
|----------|-------|
| Bucket name | `corvanta-production-storage-072718160542` |
| Versioning | **Enabled** |
| Encryption | **AES256** (SSE-S3, default bucket key) |
| Public access block | **Fully enabled** (all 4 flags true) |
| Bucket policy | None |
| Purpose | Application data (user uploads, documents) |
| Created | 2026-10-24 |

**Recommendation: Do NOT reuse this bucket for Terraform state.**

Trade-offs of reusing:
- **Pros:** Single bucket to manage
- **Cons:** Mixed IAM policies (app needs read/write; Terraform needs full control); application lifecycle vs infrastructure lifecycle; risk of accidental deletion via app code; different retention requirements; state file exposure if app code is compromised.

## Recommended Dedicated State Bucket Design

| Setting | Value |
|---------|-------|
| Bucket name | `corvanta-terraform-state-072718160542` (account ID suffix for global uniqueness) |
| Region | `eu-central-1` |
| Versioning | **Enabled** (required for state history/rollback) |
| Encryption | **AES256** (SSE-S3) |
| Public access block | **All 4 flags enabled** |
| Object lock | Not required (versioning sufficient) |
| Lifecycle | Optional: expire noncurrent versions after 90 days |

**Locking:** DynamoDB table `corvanta-terraform-locks` with primary key `LockID` (string). This is the standard, supported locking mechanism for S3 backend in Terraform 1.16.x.

## Bootstrap Provisioning Plan (Terraform-Managed)

**Important:** Keep bootstrap resources separate from the 19 existing application resources. Do not add them to existing modules.

### Option A: Separate bootstrap directory (recommended)

```
~/corvanta/corvanta-terraform/
├── bootstrap/
│   ├── main.tf        # Creates state bucket + DynamoDB table
│   ├── variables.tf
│   ├── outputs.tf
│   └── provider.tf
```

`bootstrap/main.tf` (minimal, no module dependencies):

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = "eu-central-1"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "corvanta-terraform-state-072718160542"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule { apply_server_side_encryption_by_default { sse_algorithm = "AES256" } }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "corvanta-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute { name = "LockID"; type = "S" }

  ttl { attribute_name = "TTL"; enabled = true }

  tags = {
    Project     = "Corvanta"
    Environment = "production"
    Purpose     = "Terraform state locking"
    ManagedBy   = "Terraform"
  }
}

output "state_bucket_name" { value = aws_s3_bucket.terraform_state.bucket }
output "lock_table_name"   { value = aws_dynamodb_table.terraform_locks.name }
```

### Bootstrap execution sequence (safe, preview-only):

```bash
cd ~/corvanta/corvanta-terraform/bootstrap
terraform init
terraform validate
terraform plan -out=bootstrap.tfplan
# Review: 2 resources to add (S3 bucket + DynamoDB table)
terraform apply "bootstrap.tfplan"
```

## Backend Configuration to Add (After Bootstrap)

Add to root `main.tf` (or create `backend.tf`):

```hcl
terraform {
  backend "s3" {
    bucket         = "corvanta-terraform-state-072718160542"
    key            = "corvanta/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "corvanta-terraform-locks"
  }
}
```

## Exact Migration Sequence

| Step | Command | Purpose |
|------|---------|---------|
| 1 | `cd ~/corvanta/corvanta-terraform/bootstrap && terraform init && terraform plan -out=../bootstrap.tfplan` | Preview bootstrap resources |
| 2 | `terraform apply "bootstrap.tfplan"` | Provision state bucket + lock table |
| 3 | `cd ~/corvanta/corvanta-terraform && cp terraform.tfstate terraform.tfstate.pre-migration` | Safety backup |
| 4 | Add backend block to `main.tf` (see above) | Configure remote backend |
| 5 | `terraform init -migrate-state` | **Migrate local state → S3** (Terraform will prompt `yes`) |
| 6 | `terraform plan` | Verify no-change plan (should show 0 add/change/destroy) |
| 7 | `terraform apply` (optional small change) | Verify end-to-end write path works |

**Critical:** Step 5 is the **only** step that modifies state location. Steps 1-2 only create new, independent AWS resources. Step 3 preserves the current local state file.

## Failure Recovery Procedures

| Failure Point | Recovery Action |
|---------------|-----------------|
| **Bootstrap apply fails** | No state touched; fix bootstrap config and re-apply. Existing resources unaffected. |
| **Backend block added but `init -migrate-state` fails** | Local `terraform.tfstate` is unchanged. Remove backend block, run `terraform init` (reinitializes local), continue working locally. |
| **`init -migrate-state` partially succeeds but plan shows changes** | Do NOT apply. Restore: `cp terraform.tfstate.pre-migration terraform.tfstate && rm -rf .terraform && terraform init` |
| **State migrated but lock table fails** | S3 state is written; if lock table missing, Terraform will warn but proceed. Create table separately or re-run bootstrap. |
| **Accidental `terraform apply` with remote state shows unexpected changes** | Do not confirm. Run `terraform state pull > local-backup.tfstate`, then restore from `terraform.tfstate.pre-migration` or `terraform.tfstate.backup`. |

**Never** run `terraform state rm` or `terraform import` during migration unless explicitly approved.

## Files Prepared / Expected AWS Changes

### Files to create (not yet created):
- `bootstrap/main.tf`, `bootstrap/variables.tf`, `bootstrap/outputs.tf`, `bootstrap/provider.tf`
- `backend.tf` (or add block to `main.tf`)

### Expected AWS changes (bootstrap only):
- **+1** `aws_s3_bucket` (state bucket)
- **+1** `aws_dynamodb_table` (lock table)
- **0** modifications to existing 19 resources
- **0** deletions

### Post-migration verification:
- `terraform plan` → **No changes** (proves state migration preserved all resource identities)
- All 19 existing resources remain tracked at same addresses
- State visible in S3 at `s3://corvanta-terraform-state-072718160542/corvanta/terraform.tfstate`
- Locks visible in DynamoDB table `corvanta-terraform-locks`

## Next Command Sequence (Pending Approval)

```bash
# 1. Provision bootstrap resources (safe, independent)
cd ~/corvanta/corvanta-terraform/bootstrap
terraform init && terraform validate && terraform plan -out=../bootstrap.tfplan
terraform apply "bootstrap.tfplan"

# 2. Migrate state (only after bootstrap succeeds)
cd ~/corvanta/corvanta-terraform
cp terraform.tfstate terraform.tfstate.pre-migration
# (add backend block to main.tf)
terraform init -migrate-state
# (answer 'yes' to migration prompt)
terraform plan
```

**Stop here.** Awaiting approval before:
1. Creating the bootstrap directory and files
2. Running any `terraform apply` in bootstrap
3. Adding the backend block
4. Running `terraform init -migrate-state`