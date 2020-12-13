output "account_alias" {
  value = aws_iam_account_alias.this.account_alias
}

output "application_logs_bucket_arn" {
  value = aws_s3_bucket.s3_application_logs.arn
}

output "application_logs_bucket_name" {
  value = aws_s3_bucket.s3_application_logs.id
}

output "cloudwatch_logs_kms_key_arn" {
  value = aws_kms_key.cloudwatch_logs.arn
}

output "vpc_flow_logs_role_arn" {
  value = aws_iam_role.vpc_flow_logs.arn
}

output "service_logs_bucket_arn" {
  value = aws_s3_bucket.s3_service_logs.arn
}

output "service_logs_bucket_name" {
  value = aws_s3_bucket.s3_service_logs.id
}