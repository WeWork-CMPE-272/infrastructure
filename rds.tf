// BEGIN General RDS Infrastructure
resource "aws_db_subnet_group" "we_work" {
  name        = "we-work"
  description = "Public Subnet Group in the Platform VPC"

  subnet_ids = aws_subnet.we_work_public.*.id

  tags = {
    Managed-By = "terraform"
    VPC        = "platform"
  }
}
resource "aws_db_parameter_group" "we_work" {
  name   = "rds-we-work-mysql"
  family = "mysql8.0"

 tags = {
    Managed-By = "terraform"
    VPC        = "we-work"
  }
}


// END General RDS Infrastructure