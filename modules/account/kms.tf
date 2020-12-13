// BEGIN CloudWatch Logs key
data "aws_iam_policy_document" "aws_kms_key_cloudwatch_logs" {

  // DO NOT REMOVE THIS STATEMENT
  // It is the default statement and required for access to the key, if this
  // statement is removed we will need to contact AWS support to regain access.
  statement {
    sid = "Enable IAM User Permissions"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  // https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/encrypt-log-data-kms.html
  statement {
    principals {
      type        = "Service"
      identifiers = ["logs.${local.region}.amazonaws.com"]
    }

    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = ["*"]
  }
}

resource "aws_kms_key" "cloudwatch_logs" {
  description         = "Used for encrypting CloudWatch log groups"
  policy              = data.aws_iam_policy_document.aws_kms_key_cloudwatch_logs.json
  enable_key_rotation = true

  tags = {
    Managed-By = "terraform"
  }
}

resource "aws_kms_alias" "cloudwatch_logs" {
  name          = "alias/cloudwatch-logs"
  target_key_id = aws_kms_key.cloudwatch_logs.key_id
}
// END CloudWatch Logs key