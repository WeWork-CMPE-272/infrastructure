/**
 * Allow RDS to report enhanced metrics to CloudWatch
 *
 * @see: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_Monitoring.OS.html#USER_Monitoring.OS.Enabling.Prerequisites
 *
 * BEGIN RDS Enhanced Monitoring
 */

# Allow RDS Monitoring to assume this role
data "aws_iam_policy_document" "assume_role_rds_monitoring" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "rds_monitoring" {
  name                  = "rds-monitoring-role"
  assume_role_policy    = data.aws_iam_policy_document.assume_role_rds_monitoring.json
  force_detach_policies = false
  path                  = "/service-role/rds-monitoring/"
  description           = "Allows RDS to manage CloudWatch Logs resources for Enhanced Monitoring on your behalf."
  max_session_duration  = 3600

  tags = {
    AWS-Service = "RDS"
    Managed-By  = "terraform"
    Name        = "RDS Enhanced Monitoring"
    Service     = "blog"
  }
}

# Attach AmazonRDSEnhancedMonitoringRole managed policy to the above role
resource "aws_iam_role_policy_attachment" "rds_monitoring_to_managed_policy" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
// END RDS Enhanced Monitoring