// BEGIN Frontend Load Balancer
resource "aws_security_group" "frontend_alb" {
  name   = "frontend-alb"
  vpc_id = aws_vpc.wework.id

  ingress {
    description = "Inbound HTTP Traffic"

    from_port = 80
    to_port   = 80
    protocol  = "tcp"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  ingress {
    description = "Inbound HTTPS Traffic"

    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Managed-By = "terraform"
    Name       = " ALB"
    Service    = "Frontend"
    VPC        = "wework"
  }
}

resource "aws_lb" "frontend_alb" {
  name               = "frontend"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.frontend_alb.id]

  access_logs {
    bucket  = module.base_account.application_logs_bucket_name
    prefix  = "lb-frontend"
    enabled = true
  }

  subnets = aws_subnet.wework_public.*.id

  idle_timeout                     = 300
  enable_deletion_protection       = true
  enable_cross_zone_load_balancing = true

  tags = {
    Managed-By = "terraform"
    Service    = "Frontend"
    VPC        = "wework"
  }
}

resource "aws_lb_target_group" "frontend_alb" {
  name                 = "frontend"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = aws_vpc.wework.id
  deregistration_delay = local.is_production ? 300 : 1

  health_check {
    interval            = 10
    path                = "/health"
    port                = "80"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  target_type = "ip"

  tags = {
    Managed-By = "terraform"
    Service    = "Frontend"
    VPC        = "wework"
  }
}

resource "aws_lb_listener" "frontend_alb_http" {
  load_balancer_arn = aws_lb.frontend_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

/**
 * See the following document for a list of SSL Polices
 * https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-security-policy-table.html
 */
resource "aws_lb_listener" "frontend_alb_https" {
  load_balancer_arn = aws_lb.frontend_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = local.environment.ssl_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_alb.arn
  }
}
// END Frontend Load Balancer

// BEGIN Security Group
resource "aws_security_group" "frontend" {
  name   = "frontend"
  vpc_id = aws_vpc.wework.id

  egress {
    description = "Outbound NTP traffic"

    from_port = 123
    to_port   = 123
    protocol  = "udp"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  egress {
    description = "Outbound HTTP Traffic"

    protocol  = "tcp"
    from_port = 80
    to_port   = 80

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  egress {
    description = "Outbound HTTPS Traffic"

    protocol  = "tcp"
    from_port = 443
    to_port   = 443

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  egress {
    description = "Outbound traffic to DB"

    protocol  = "tcp"
    from_port = 32768
    to_port   = 32768

    cidr_blocks = [
 "0.0.0.0/0"
     ]
  }

resource "aws_security_group_rule" "ingress_frontend_from_frontend_alb" {
  description = "Inbound traffic from ALB"

  type      = "ingress"
  from_port = 80
  to_port   = 80
  protocol  = "tcp"

  source_security_group_id = aws_security_group.frontend_alb.id
  security_group_id        = aws_security_group.frontend.id
}

resource "aws_security_group_rule" "ingress_frontend_from_dashboard_server" {
  description = "Inbound traffic from Dashboard Server"

  type      = "ingress"
  from_port = 8081
  to_port   = 8081
  protocol  = "tcp"

  source_security_group_id = aws_security_group.dashboard_server.id
  security_group_id        = aws_security_group.frontend.id
}

resource "aws_security_group_rule" "ingress_frontend_from_payments_listener" {
  description = "Inbound traffic from Payments Listener"

  type      = "ingress"
  from_port = 8081
  to_port   = 8081
  protocol  = "tcp"

  source_security_group_id = aws_security_group.payments_listener.id
  security_group_id        = aws_security_group.frontend.id
}

resource "aws_security_group_rule" "ingress_frontend_from_webhook_executor" {
  description = "Inbound traffic from Webhook Executor"

  type      = "ingress"
  from_port = 8081
  to_port   = 8081
  protocol  = "tcp"

  source_security_group_id = aws_security_group.webhook_executor.id
  security_group_id        = aws_security_group.frontend.id
}
// END Security Group

resource "aws_cloudwatch_log_group" "ecs_wework_frontend" {
  name       = "/ecs/wework/frontend"
  kms_key_id = module.base_account.cloudwatch_logs_kms_key_arn

  tags = {
    Managed-By = "terraform"
    Service    = "Frontend"
  }
}

// BEGIN IAM
resource "aws_iam_role" "ecs_task_frontend" {
  name               = "ecs-task-frontend"
  assume_role_policy = data.aws_iam_policy_document.assume_role_ecs_tasks.json
  path               = "/ecs/tasks/"

  tags = {
    Managed-By = "terraform"
    Service    = "Frontend"
  }
}

// END IAM

// BEGIN ECR
resource "aws_ecr_repository" "wework_frontend" {
  name                 = "wework/frontend"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Managed-By = "terraform"
    Service    = "Frontend"
  }
}

resource "aws_ecr_repository_policy" "wework_frontend_codebuild" {
  repository = aws_ecr_repository.wework_frontend.name
  policy     = data.aws_iam_policy_document.code_build_access.json
}

resource "aws_ecr_lifecycle_policy" "wework_frontend" {
  repository = aws_ecr_repository.wework_frontend.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "delete untagged",
        selection = {
          countType   = "sinceImagePushed",
          countUnit   = "days",
          countNumber = 5,
          tagStatus   = "untagged"
        },
        action = {
          type = "expire"
        },
      },
    ]
  })
}
// END ECR

resource "aws_ecs_task_definition" "frontend" {
  family = "frontend"
  container_definitions = templatefile(
    "${path.module}/container-definitions/frontend.tpl.json",
    {
      environment   = "production"
      image         = aws_ecr_repository.wework_frontend.repository_url
      region        = local.region
      kms_key       = aws_kms_key.application_config.key_id
      awslogs_group = aws_cloudwatch_log_group.ecs_wework_frontend.name
    }
  )
  task_role_arn            = aws_iam_role.ecs_task_frontend.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]

  tags = {
    Managed-By = "terraform"
    Service    = "Frontend"
    VPC        = "wework"
  }
}
// END Frontend Task

// BEGIN Frontend Service
resource "aws_ecs_service" "frontend" {
  name    = "frontend"
  cluster = aws_ecs_cluster.wework.arn

  deployment_controller { type = "ECS" }
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  desired_count                      = 2

  enable_ecs_managed_tags           = true
  health_check_grace_period_seconds = 15
  launch_type                       = "EC2"

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend_alb.arn
    container_name   = "frontend"
    container_port   = 80
  }

  network_configuration {
    subnets          = aws_subnet.wework_public.*.id
    security_groups  = [aws_security_group.frontend.id]
    assign_public_ip = false
  }

  # reference: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-placement.html
  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }

  propagate_tags      = "SERVICE"
  scheduling_strategy = "REPLICA"

  service_registries {
    registry_arn = aws_service_discovery_service.frontend.arn
  }

  task_definition = aws_ecs_task_definition.frontend.arn

  tags = {
    Managed-By = "terraform"
    Service    = "Frontend"
    VPC        = "wework"
  }

  lifecycle {
    ignore_changes = [
      task_definition,
      desired_count,
    ]
  }
}

// END Frontend Service

// BEGIN Frontend Service Discovery
resource "aws_service_discovery_service" "frontend" {
  name = "frontend"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.wework.id

    dns_records {
      ttl  = 60
      type = "A"
    }

    routing_policy = "WEIGHTED"
  }
}

// END Frontend Service Discovery

// BEGIN Frontend Service Task Autoscaling
resource "aws_appautoscaling_target" "frontend" {
  max_capacity       = 10
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.wework.name}/${aws_ecs_service.frontend.name}"
  role_arn           = aws_iam_service_linked_role.ecs_application_autoscaling.arn
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "frontend_scale_up" {
  name               = "frontend-scale-up"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.frontend.resource_id
  scalable_dimension = aws_appautoscaling_target.frontend.scalable_dimension
  service_namespace  = aws_appautoscaling_target.frontend.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 120
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

resource "aws_appautoscaling_policy" "frontend_scale_down" {
  name               = "frontend-scale-down"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.frontend.resource_id
  scalable_dimension = aws_appautoscaling_target.frontend.scalable_dimension
  service_namespace  = aws_appautoscaling_target.frontend.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 120
    metric_aggregation_type = "Average"
  }
}

resource "aws_cloudwatch_metric_alarm" "frontend_scale_up" {
  alarm_name          = "frontend-scale-up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 75

  dimensions = {
    ClusterName = aws_ecs_cluster.wework.name
    ServiceName = aws_ecs_service.frontend.name
  }

  tags = {
    Managed-By = "terraform"
    Service    = "Frontend"
    VPC        = "wework"
  }
}

resource "aws_cloudwatch_metric_alarm" "frontend_scale_down" {
  alarm_name          = "frontend-scale-down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 35 # Frontend idles at 31%

  dimensions = {
    ClusterName = aws_ecs_cluster.wework.name
    ServiceName = aws_ecs_service.frontend.name
  }

  tags = {
    Managed-By = "terraform"
    Service    = "Frontend"
    VPC        = "wework"
  }
}

// END Frontend Service Task Autoscaling