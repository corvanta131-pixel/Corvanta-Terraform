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

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "practice" {
  bucket = "corvanta-terraform-practice-${data.aws_caller_identity.current.account_id}"

  tags = {
    Project     = "Corvanta"
    Environment = "practice"
    ManagedBy   = "Terraform"
  }
}

module "network" {
  source = "./modules/network"

  project_name        = var.project_name
  environment         = var.environment
  vpc_cidr            = "10.0.0.0/16"
  public_subnet_cidr  = "10.0.1.0/24"
  private_subnet_cidr = "10.0.2.0/24"
  availability_zone   = "eu-central-1a"
}

module "compute" {
  source = "./modules/compute"

  project_name              = var.project_name
  environment               = var.environment
  instance_type             = var.backend_instance_type
  subnet_id                 = module.network.public_subnet_id
  vpc_id                    = module.network.vpc_id
  iam_instance_profile_name = aws_iam_instance_profile.corvanta_ec2.name
  public_key_path           = "/home/louis/.ssh/corvanta-practice.pub"
}