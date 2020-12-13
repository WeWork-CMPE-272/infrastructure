locals {
  s3_application_logs_bucket = "${local.account_id}-application-logs"
}

data "aws_elb_service_account" "this" {}

data "aws_iam_policy_document" "s3_application_logs" {

  // BEGIN Load Balancers
  // ELB Reference: https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-access-logs.html
  // ALB Reference: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html
  // NLB Reference: https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-access-logs.html
  statement {
    sid       = "elb:PutObject"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${local.s3_application_logs_bucket}/lb-*"]

    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.this.arn]
    }
  }

  statement {
    sid       = "lb:PutObject"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${local.s3_application_logs_bucket}/lb-*"]

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
    sid       = "lb:GetBucketAcl"
    actions   = ["s3:GetBucketAcl"]
    resources = ["arn:aws:s3:::${local.s3_application_logs_bucket}"]

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }
  // END Load Balancers

}

resource "aws_s3_bucket" "s3_application_logs" {
  bucket = local.s3_application_logs_bucket
  acl    = "private"

  policy = data.aws_iam_policy_document.s3_application_logs.json

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

resource "aws_s3_bucket_public_access_block" "s3_application_logs" {
  bucket = aws_s3_bucket.s3_application_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
