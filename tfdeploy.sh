#!/bin/bash

set -e

echo "========================================"
echo " Terraform Format"
echo "========================================"
terraform fmt

echo
echo "========================================"
echo " Terraform Validate"
echo "========================================"
terraform validate

echo
echo "========================================"
echo " Terraform Plan"
echo "========================================"
terraform plan

echo
echo "========================================"
read -p "Apply this Terraform plan? Type yes to continue: " answer

if [ "$answer" = "yes" ]; then
    echo
    echo "========================================"
    echo " Terraform Apply"
    echo "========================================"
    terraform apply -auto-approve

    echo
    echo "Terraform apply completed."
else
    echo
    echo "Apply cancelled."
fi
