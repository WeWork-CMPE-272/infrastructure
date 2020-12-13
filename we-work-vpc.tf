/**
 * We Work Network
 * 
 * BEGIN Network
 */
locals {
  _we_work_vpc_ip_prefix = "10.16"

  we_work_vpc = {
    name              = "we_work"
    cidr_block        = "${local._we_work_vpc_ip_prefix}.0.0/16"
    nat_gateway_count =  1
    // BEGIN subnet_cidr_blocks
    subnet_cidr_blocks = {
      public = {
        range = "${local._we_work_vpc_ip_prefix}.0.0/20"
        zones = [
          "${local._we_work_vpc_ip_prefix}.0.0/23",
          "${local._we_work_vpc_ip_prefix}.2.0/23",
        ]
      }
    }
    // END subnet_cidr_blocks
  }
}
resource "aws_vpc" "we_work" {
  cidr_block           = local.we_work_vpc.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Managed-By = "terraform"
    Name       = "we_work"
    VPC        = local.we_work_vpc.name
  }
}
// BEGIN Default Resources
/**
 * Default network ACL for VPC
 *
 * Managed via terraform to prevent against security holes using this NACL
 *
 * @see https://www.terraform.io/docs/providers/aws/r/default_network_acl.html
 * @see https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html#default-network-acl
 */
resource "aws_default_network_acl" "we_work" {
  default_network_acl_id = aws_vpc.we_work.default_network_acl_id
  tags = {
    Managed-By = "terraform"
    Name       = "Default"
    VPC        = local.we_work_vpc.name
  }
}
/**
 * Default route table for VPC
 *
 * By default this table has a single route (local route) that cannot be
 * removed. Do not add any additional routes to this table because all new
 * subnets are automatically associated with this route table.
 *
 * @see https://www.terraform.io/docs/providers/aws/r/default_route_table.html
 * @see https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html#RouteTableDetails
 */
resource "aws_default_route_table" "we_work" {
  default_route_table_id = aws_vpc.we_work.default_route_table_id
  tags = {
    Managed-By = "terraform"
    Name       = "Default"
    VPC        = local.we_work_vpc.name
  }
}
/**
 * Default security group for VPC
 *
 * Managed via terraform to prevent against security holes using this SG
 *
 * @see https://www.terraform.io/docs/providers/aws/r/default_security_group.html
 * @see https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-network-security.html#default-security-group
 */
resource "aws_default_security_group" "we_work" {
  vpc_id = aws_vpc.we_work.id
  tags = {
    Managed-By = "terraform"
    Name       = "Default"
    VPC        = local.we_work_vpc.name
  }
}
// END Default Resources
// BEGIN Flow Logs
resource "aws_cloudwatch_log_group" "flow_logs_we_work" {
  name              = "/flow-logs/we_work"
  kms_key_id        = module.account.cloudwatch_logs_kms_key_arn
  retention_in_days = 14
  tags = {
    Managed-By = "terraform"
    Service    = "we_work VPC"
    VPC        = local.we_work_vpc.name
  }
}
resource "aws_flow_log" "we_work_cloudwatch" {
  traffic_type             = "ALL"
  iam_role_arn             = module.account.vpc_flow_logs_role_arn
  log_destination_type     = "cloud-watch-logs"
  log_destination          = aws_cloudwatch_log_group.flow_logs_we_work.arn
  vpc_id                   = aws_vpc.we_work.id
  max_aggregation_interval = 60
  tags = {
    Managed-By = "terraform"
    Name       = "we_work VPC CloudWatch Logs"
    VPC        = local.we_work_vpc.name
  }
}
resource "aws_flow_log" "we_work_s3" {
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = "${module.account.service_logs_bucket_arn}/flowlogs-${aws_vpc.we_work.id}/"
  vpc_id               = aws_vpc.we_work.id
  log_format = join(" ", [
    "$${version}",
    "$${account-id}",
    "$${vpc-id}",      # custom
    "$${subnet-id}",   # custom
    "$${instance-id}", # custom
    "$${interface-id}",
    "$${srcaddr}",
    "$${dstaddr}",
    "$${srcport}",
    "$${dstport}",
    "$${pkt-srcaddr}", # custom
    "$${pkt-dstaddr}", # custom
    "$${protocol}",
    "$${tcp-flags}", # custom
    "$${packets}",
    "$${bytes}",
    "$${start}",
    "$${end}",
    "$${action}",
    "$${log-status}",
  ])
  max_aggregation_interval = 600
  tags = {
    Managed-By = "terraform"
    Name       = "we_work VPC S3"
    VPC        = local.we_work_vpc.name
  }
}
// END Flow Logs
// BEGIN VPC Level Constructs
resource "aws_route53_zone" "we_work" {
  name = "we-work"
  vpc {
    vpc_id     = aws_vpc.we_work.id
    vpc_region = local.region
  }
  tags = {
    Managed-By = "terraform"
    Service    = "we_work VPC"
    VPC        = local.we_work_vpc.name
  }
}
resource "aws_internet_gateway" "we_work" {
  vpc_id = aws_vpc.we_work.id
  tags = {
    Managed-By = "terraform"
    Service    = "we_work VPC"
    VPC        = local.we_work_vpc.name
  }
}

// END VPC Level Constructs
// BEGIN NAT Gateways
resource "aws_eip" "nat_gateway_we_work" {
  count = local.we_work_vpc.nat_gateway_count
  vpc = true
  tags = {
    Managed-By = "terraform"
    Name       = "NAT Gateway - we_work ${count.index + 1}"
    Service    = "we_work VPC"
    VPC        = local.we_work_vpc.name
  }
}
resource "aws_nat_gateway" "we_work" {
  count = local.we_work_vpc.nat_gateway_count
  allocation_id = aws_eip.nat_gateway_we_work[count.index].id
  subnet_id     = aws_subnet.we_work_public[count.index].id
  tags = {
    Managed-By = "terraform"
    Name       = "we_work ${count.index + 1}"
    Service    = "we_work VPC"
    VPC        = local.we_work_vpc.name
  }
}
// END NAT Gateways
// BEGIN Subnets
// BEGIN Public Subnet
resource "aws_subnet" "we_work_public" {
  count = length(local.we_work_vpc.subnet_cidr_blocks.public.zones)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = local.we_work_vpc.subnet_cidr_blocks.public.zones[count.index]
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.we_work.id
  tags = {
    Managed-By = "terraform"
    Name       = "Public Subnet ${count.index + 1}"
    VPC        = local.we_work_vpc.name
  }
}
resource "aws_route_table" "we_work_public" {
  vpc_id = aws_vpc.we_work.id
  # Unmatched traffic -> Internet Gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.we_work.id
  }
  tags = {
    Managed-By = "terraform"
    Name       = "Public"
    VPC        = local.we_work_vpc.name
  }
}
resource "aws_route_table_association" "we_work_public" {
  count = length(local.we_work_vpc.subnet_cidr_blocks.public.zones)
  route_table_id = aws_route_table.we_work_public.id
  subnet_id      = aws_subnet.we_work_public[count.index].id
}
resource "aws_network_acl" "we_work_public" {
  subnet_ids = aws_subnet.we_work_public.*.id
  vpc_id = aws_vpc.we_work.id
  # NTP
  ingress {
    rule_no = 100
    action  = "allow"
    protocol   = "udp"
    cidr_block = "0.0.0.0/0"
    from_port = 123
    to_port   = 123
  }
  # HTTP
  ingress {
    rule_no = 200
    action  = "allow"
    protocol   = "tcp"
    cidr_block = "0.0.0.0/0"
    from_port = 80
    to_port   = 80
  }
  # HTTPS
  ingress {
    rule_no = 210
    action  = "allow"
    protocol   = "tcp"
    cidr_block = "0.0.0.0/0"
    from_port = 443
    to_port   = 443
  }
  
  # Ephemeral Ports
  # Requests made to the internet will have their responses returned on ephemeral ports
  # make this last rule so certain ports in the range can be blocked if need be
  # see: https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html#nacl-ephemeral-ports
  ingress {
    rule_no = 900
    action  = "allow"
    protocol   = "tcp"
    cidr_block = "0.0.0.0/0"
    from_port = 1024
    to_port   = 65535
  }
  //    //    //
  # NTP
  egress {
    rule_no = 100
    action  = "allow"
    protocol   = "udp"
    cidr_block = "0.0.0.0/0"
    from_port = 123
    to_port   = 123
  }
  # HTTP
  egress {
    rule_no = 200
    action  = "allow"
    protocol   = "tcp"
    cidr_block = "0.0.0.0/0"
    from_port = 80
    to_port   = 80
  }
  # HTTPS
  egress {
    rule_no = 210
    action  = "allow"
    protocol   = "tcp"
    cidr_block = "0.0.0.0/0"
    from_port = 443
    to_port   = 443
  }

  # Ephemeral Ports
  # Requests made to our servers will have their response sent out on ephemeral ports
  # make this last rule so certain ports in the range can be blocked if need be
  # see: https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html#nacl-ephemeral-ports
  egress {
    rule_no = 900
    action  = "allow"
    protocol   = "tcp"
    cidr_block = "0.0.0.0/0"
    from_port = 1024
    to_port   = 65535
  }
  tags = {
    Managed-By = "terraform"
    Name       = "Public ACL"
    VPC        = local.we_work_vpc.name
  }
}
// END Public Subnet