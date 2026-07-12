terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {}
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = terraform.workspace
      ManagedBy   = "Terraform"
      Project     = "multi-env-infra"
    }
  }
}

locals {
  environment = terraform.workspace
  name_prefix = "${var.project_name}-${local.environment}"
}

module "main_network" {
  source = "./modules/network"

  environment = local.environment
  name_prefix = local.name_prefix
  vpc_cidr    = var.vpc_cidr
  az_count    = var.az_count
}

module "main_compute" {
  source = "./modules/compute"

  environment        = local.environment
  name_prefix        = local.name_prefix
  vpc_id             = module.main_network.vpc_id
  public_subnet_ids  = module.main_network.public_subnet_ids
  private_subnet_ids = module.main_network.private_subnet_ids
  instance_type      = var.instance_type
  instance_count     = var.instance_count
  allowed_ssh_cidrs  = var.allowed_ssh_cidrs
}

resource "aws_s3_bucket" "app_data" {
  bucket = "${local.name_prefix}-app-data-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "${local.name_prefix}-app-data"
  }
}

resource "aws_s3_bucket_public_access_block" "app_data" {
  bucket = aws_s3_bucket.app_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app_data" {
  bucket = aws_s3_bucket.app_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

data "aws_caller_identity" "current" {}
