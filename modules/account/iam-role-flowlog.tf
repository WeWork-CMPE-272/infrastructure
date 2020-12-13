/**
 * Creates an IAM Role that allows VPC Flow Logs to publish to CloudWatch Logs
 */
data "aws_iam_policy_document" "assume_role_vpc_flow_logs" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "vpc_flow_logs" {
  name                  = "vpc-flow-logs"
  assume_role_policy    = data.aws_iam_policy_document.assume_role_vpc_flow_logs.json
  force_detach_policies = false
  path                  = "/service-role/vpc-flow-logs/"
  description           = "Allows VPC Flow Logs to push to CloudWatch."
  max_session_duration  = 3600

  tags = {
    Managed-By = "terraform:account"
    Name       = "VPC Flow Logs"
  }
}

data "aws_iam_policy_document" "vpc_flow_logs_cloudwatch" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = [
      "arn:aws:logs:${local.arn_region_account_id}:log-group:/flow-logs/*",
    ]
  }
}

resource "aws_iam_role_policy" "vpc_flow_logs_cloudwatch" {
  name   = "vpc-flow-logs-cloudwatch"
  role   = aws_iam_role.vpc_flow_logs.id
  policy = data.aws_iam_policy_document.vpc_flow_logs_cloudwatch.json
}