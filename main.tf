terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.46.0"
    }
  }
  backend "s3" {
    bucket = "simons-terraform-state"
    key    = "incoming-email-forward"
    region = "eu-central-1"
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      CreatedBy  = "Terraform"
      ScriptName = "Incoming-Email-Forward"
    }
  }

}

data "aws_caller_identity" "current" {}
locals {
  aws_account_id = data.aws_caller_identity.current.account_id
}
