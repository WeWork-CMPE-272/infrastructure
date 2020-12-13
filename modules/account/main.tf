data "aws_caller_identity" "this" {}
data "aws_region" "this" {}

locals {
  account_id            = data.aws_caller_identity.this.account_id
  region                = data.aws_region.this.name
  arn_region_account_id = "${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}"
}

# Used for the console login URL: https://we-work.signin.aws.amazon.com/console
resource "aws_iam_account_alias" "this" {
  account_alias = "we-work"
}

# Organization accounts shouldn't have users in the first place, but strengthen
# rules in case users are created for temporary purposes.
resource "aws_iam_account_password_policy" "this" {
  allow_users_to_change_password = false
  hard_expiry                    = true
  max_password_age               = 15
  minimum_password_length        = 60
  password_reuse_prevention      = 1
  require_lowercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  require_uppercase_characters   = true
}