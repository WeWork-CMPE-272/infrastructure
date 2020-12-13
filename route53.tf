# SSL Certificate
data "aws_acm_certificate" "wildcard_we-work_com" {
  domain   = "*.we-work.info"
  statuses = ["ISSUED"]
  types    = ["AMAZON_ISSUED"]
}

data "aws_acm_certificate" "EAST_wildcard_we-work_com" {
  domain   = "we-work.info"
  statuses = ["ISSUED"]
  types    = ["AMAZON_ISSUED"]
}

// BEGIN we-work.info
resource "aws_route53_zone" "we-work_com" {
  name = "we-work.info."
}


// END we-work.info
