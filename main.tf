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
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

module "network" {
  source = "./modules/network"

  project_name        = var.project_name
  environment         = var.environment
  vpc_cidr            = "10.0.0.0/16"
  public_subnet_cidr  = "10.0.1.0/24"
  private_subnet_cidr = "10.0.2.0/24"
  availability_zone   = "${var.aws_region}a"
}

module "storage" {
  source = "./modules/storage"

  project_name = var.project_name
  environment  = var.environment
  account_id   = data.aws_caller_identity.current.account_id
}

module "messaging" {
  source = "./modules/messaging"

  project_name               = var.project_name
  environment                = var.environment
  visibility_timeout_seconds = 60
  message_retention_seconds  = 86400
}

module "iam" {
  source = "./modules/iam"

  project_name  = var.project_name
  environment   = var.environment
  s3_bucket_arn = module.storage.s3_bucket_arn
  sqs_queue_arn = module.messaging.sqs_queue_arn
}

module "compute" {
  source = "./modules/compute"

  project_name              = var.project_name
  environment               = var.environment
  instance_type             = var.backend_instance_type
  subnet_id                 = module.network.public_subnet_id
  vpc_id                    = module.network.vpc_id
  iam_instance_profile_name = module.iam.iam_instance_profile_name
  ssh_public_key_path       = var.ssh_public_key_path
  admin_cidr_block          = var.admin_cidr_block
}
