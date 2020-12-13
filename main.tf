terraform {
  backend "remote" {
    organization = "we-work"

    workspaces {
      name = "we-work"
    }
  }

    required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  required_version = ">= 0.13.0, < 0.14.0"

}

provider "aws" {
  region              = "us-east-1"
  access_key = "AKIA4GF2HVKXRACFCDHZ"
  secret_key = "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"
  allowed_account_ids = ["837909195439"]
}

# provider "aws" {
#   region              = "us-east-1"
#   alias               = "us_east_1"
#   access_key = "AKIA4GF2HVKX5G2R5AE4"
#   secret_key = "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"
#   allowed_account_ids = ["837909195439"]
# }

// BEGIN Global Modules
module "account" {
  source = "./modules/account"
}

locals {
  region                = data.aws_region.current.name
  account_id            = data.aws_caller_identity.main.account_id
  arn_region_account_id = "${local.region}:${local.account_id}"

  # These variables are used by files that are symlinked & shared between production and QA
  environment = {
    dns_zone_id                 = aws_route53_zone.we-work_com.zone_id
    platform_beanstalk_key_name = null
    ssl_certificate_arn         = data.aws_acm_certificate.wildcard_we-work_com.arn
    # EAST_ssl_certificate_arn    = data.aws_acm_certificate.EAST_we-work_smartcar_com.arn
  }
}

// BEGIN Shared data resources
data "aws_region" "current" {}
data "aws_caller_identity" "main" {}
data "aws_elb_service_account" "main" {}
data "aws_elastic_beanstalk_hosted_zone" "main" {}
data "aws_availability_zones" "available" {
  state = "available"
}