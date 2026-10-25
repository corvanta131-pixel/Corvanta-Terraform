#!/usr/bin/env bash
#
# Safe preparation and review helper for the Corvanta Terraform project.
#
# It formats, validates and plans the configuration, then stops.
# It never applies changes: applying is a deliberate, reviewed manual step.

set -euo pipefail

cd "$(dirname "$0")"

echo "========================================"
echo " Terraform Format"
echo "========================================"
terraform fmt -recursive

echo
echo "========================================"
echo " Terraform Validate"
echo "========================================"
terraform validate

echo
echo "========================================"
echo " Terraform Plan (review only, no changes are made)"
echo "========================================"
terraform plan -out=corvanta-review.tfplan

echo
echo "========================================"
echo " Review the plan above before applying."
echo "========================================"
echo
echo "Apply explicitly and only after the plan has been reviewed:"
echo "  terraform show corvanta-review.tfplan"
echo "  terraform apply corvanta-review.tfplan"
echo
echo "This script intentionally does not run 'terraform apply'."
