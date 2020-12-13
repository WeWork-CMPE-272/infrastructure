// BEGIN KMS Key
data "aws_iam_policy_document" "aws_kms_key_rds_we_work" {

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
}

resource "aws_kms_key" "rds_we_work" {
  description         = "Used for encrypting \"wework\" RDS"
  policy              = data.aws_iam_policy_document.aws_kms_key_rds_we_work.json
  enable_key_rotation = true

  tags = {
    Managed-By = "terraform"
  }
}

resource "aws_kms_alias" "rds_we_work" {
  name          = "alias/rds-we_work"
  target_key_id = aws_kms_key.rds_we_work.key_id
}
// END KMS

// BEGIN Security Group
resource "aws_security_group" "wework_rds" {
  name   = "wework-rds"
  vpc_id = aws_vpc.we_work.id

  tags = {
    Managed-By = "terraform"
    Name       = "wework RDS"
    VPC        = "platform"
  }
}

resource "aws_security_group_rule" "ingress_wework_rds_from_api" {
  description = "Inbound traffic from API"

  type      = "ingress"
  from_port = 3306
  to_port   = 3306
  protocol  = "tcp"

  source_security_group_id = aws_security_group.we_work.id
  security_group_id        = aws_security_group.wework_rds.id
}

resource "aws_db_instance" "we_work" {
  allow_major_version_upgrade = false
  apply_immediately           = false
  auto_minor_version_upgrade  = false
  backup_retention_period     = 7
  backup_window               = "07:00-08:00" # UTC
  copy_tags_to_snapshot       = true
  db_subnet_group_name        = aws_db_subnet_group.we_work.id
  delete_automated_backups    = true
  deletion_protection         = true

  enabled_cloudwatch_logs_exports = [
    "error",
    "general",
    "slowquery",
  ]

  engine                              = "mysql"
  engine_version                      = "8.0.20"
  final_snapshot_identifier           = "we-work-final"
  iam_database_authentication_enabled = false
  identifier                          = "we-work"
  instance_class                      = "db.t3.micro"
  kms_key_id                          = aws_kms_key.rds_we_work.arn
  maintenance_window                  = "thu:08:10-thu:08:40"
  allocated_storage                   = 20
  max_allocated_storage               = 1024
  monitoring_interval                 = 60
  monitoring_role_arn                 = aws_iam_role.rds_monitoring.arn
  multi_az                            = false
  name                                = "wework"
  parameter_group_name                = aws_db_parameter_group.we_work.name
  password                            = "test-password"
  port                                = 3306
  publicly_accessible                 = true
  skip_final_snapshot                 = false
  storage_encrypted                   = true
  storage_type                        = "gp2"
  username                            = "wework"

  vpc_security_group_ids = [
    aws_security_group.wework_rds.id,
  ]

#   performance_insights_enabled          = true
#   performance_insights_kms_key_id       = aws_kms_key.rds_we_work.arn
#   performance_insights_retention_period = 7

  tags = {
    Managed-By = "terraform"
    VPC        = "wework"
  }

  # Ignore changes to the "password" property so it does not get persisted
  # into the tfstate file
  lifecycle {
    ignore_changes = [password]
  }
}
