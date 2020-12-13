
locals {
  s3_service_logs_bucket = "${local.account_id}-service-logs"
}

data "aws_redshift_service_account" "this" {}

data "aws_iam_policy_document" "s3_service_logs" {

  // BEGIN VPC Flow Logs
  // Reference: https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs-s3.html
  statement {
    sid       = "flowlogs:PutObject"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${local.s3_service_logs_bucket}/flowlogs-*"]

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid       = "flowlogs:GetBucketAcl"
    actions   = ["s3:GetBucketAcl"]
    resources = ["arn:aws:s3:::${local.s3_service_logs_bucket}"]

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }
  // END VPC Flow Logs
}

resource "aws_s3_bucket" "s3_service_logs" {
  bucket = local.s3_service_logs_bucket
  acl    = "private"

  policy = data.aws_iam_policy_document.s3_service_logs.json

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Managed-By = "terraform:account"
  }
}

resource "aws_s3_bucket_public_access_block" "s3_service_logs" {
  bucket = aws_s3_bucket.s3_service_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
