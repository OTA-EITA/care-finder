resource "aws_ecs_cluster" "main" {
  name = local.name

  setting {
    name  = "containerInsights"
    value = "enhanced"
  }
}

locals {
  image         = "${aws_ecr_repository.app.repository_url}:${var.image_tag}"
  db_secret_arn = aws_rds_cluster.main.master_user_secret[0].secret_arn

  app_environment = [
    { name = "RAILS_ENV", value = "production" },
    { name = "RAILS_LOG_LEVEL", value = "info" },
    { name = "APP_HOSTS", value = join(",", var.app_hosts) },
    { name = "APP_HOST", value = var.app_hosts[0] },
    { name = "APP_REVISION", value = var.image_tag },
    { name = "ASSET_HOST", value = "https://${aws_cloudfront_distribution.assets.domain_name}" },
    { name = "DB_HOST", value = aws_rds_cluster.main.endpoint },
    { name = "DB_NAME", value = aws_rds_cluster.main.database_name },
    { name = "REDIS_URL", value = "rediss://${aws_elasticache_replication_group.main.primary_endpoint_address}:6379/0" },
    { name = "SEARCH_BACKEND", value = "mysql" },
    { name = "OTEL_ENABLED", value = var.enable_datadog ? "1" : "0" },
    { name = "OTEL_SERVICE_NAME", value = "care-finder" },
    { name = "OTEL_EXPORTER_OTLP_ENDPOINT", value = "http://127.0.0.1:4318" },
  ]

  app_secrets = [
    { name = "SECRET_KEY_BASE", valueFrom = aws_secretsmanager_secret.secret_key_base.arn },
    { name = "DB_USERNAME", valueFrom = "${local.db_secret_arn}:username::" },
    { name = "DB_PASSWORD", valueFrom = "${local.db_secret_arn}:password::" },
    { name = "SMTP_USERNAME", valueFrom = "${aws_secretsmanager_secret.smtp.arn}:username::" },
    { name = "SMTP_PASSWORD", valueFrom = "${aws_secretsmanager_secret.smtp.arn}:password::" },
  ]

  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.app.name
      awslogs-region        = var.region
      awslogs-stream-prefix = "app"
    }
  }

  # Datadog Agent をサイドカーで動かし、アプリからの OTLP（127.0.0.1:4318）を受けて APM に送る
  datadog_container = {
    name      = "datadog-agent"
    image     = "public.ecr.aws/datadog/agent:7"
    essential = false
    environment = [
      { name = "ECS_FARGATE", value = "true" },
      { name = "DD_SITE", value = "ap1.datadoghq.com" },
      { name = "DD_OTLP_CONFIG_RECEIVER_PROTOCOLS_HTTP_ENDPOINT", value = "0.0.0.0:4318" },
      { name = "DD_LOGS_ENABLED", value = "false" },
    ]
    secrets          = [{ name = "DD_API_KEY", valueFrom = var.datadog_api_key_secret_arn }]
    logConfiguration = local.log_configuration
  }

  sidecars = var.enable_datadog ? [local.datadog_container] : []
}

resource "aws_ecs_task_definition" "web" {
  family                   = "${local.name}-web"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.web_cpu
  memory                   = var.web_memory
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode(concat([{
    name                   = "web"
    image                  = local.image
    essential              = true
    readonlyRootFilesystem = false
    portMappings           = [{ containerPort = 3000, protocol = "tcp" }]
    environment            = local.app_environment
    secrets                = local.app_secrets
    logConfiguration       = local.log_configuration
    stopTimeout            = 30
  }], local.sidecars))
}

# Solid Queue のワーカー（検索索引の更新など）。Web とは別サービスにして、片方の負荷がもう片方に響かないようにする
resource "aws_ecs_task_definition" "jobs" {
  family                   = "${local.name}-jobs"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode(concat([{
    name             = "jobs"
    image            = local.image
    essential        = true
    command          = ["./bin/jobs"]
    environment      = local.app_environment
    secrets          = local.app_secrets
    logConfiguration = local.log_configuration
  }], local.sidecars))
}

resource "aws_ecs_service" "web" {
  name                   = "web"
  cluster                = aws_ecs_cluster.main.id
  task_definition        = aws_ecs_task_definition.web.arn
  desired_count          = var.web_desired_count
  launch_type            = "FARGATE"
  enable_execute_command = true

  health_check_grace_period_seconds = 30

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  # 新しいタスクが起動しないときは自動で前の版に戻す
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = [for s in aws_subnet.private : s.id]
    security_groups  = [aws_security_group.app.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.web.arn
    container_name   = "web"
    container_port   = 3000
  }

  lifecycle {
    # オートスケールで変わる台数は Terraform で戻さない
    ignore_changes = [desired_count]
  }

  depends_on = [aws_lb_listener.https]
}

resource "aws_ecs_service" "jobs" {
  name                   = "jobs"
  cluster                = aws_ecs_cluster.main.id
  task_definition        = aws_ecs_task_definition.jobs.arn
  desired_count          = 1
  launch_type            = "FARGATE"
  enable_execute_command = true

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = [for s in aws_subnet.private : s.id]
    security_groups  = [aws_security_group.app.id]
    assign_public_ip = false
  }
}

resource "aws_appautoscaling_target" "web" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.web.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.web_desired_count
  max_capacity       = var.web_desired_count * 4
}

resource "aws_appautoscaling_policy" "web_cpu" {
  name               = "${local.name}-web-cpu"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.web.service_namespace
  resource_id        = aws_appautoscaling_target.web.resource_id
  scalable_dimension = aws_appautoscaling_target.web.scalable_dimension

  target_tracking_scaling_policy_configuration {
    target_value       = 60
    scale_in_cooldown  = 300
    scale_out_cooldown = 60

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}
