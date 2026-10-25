# アラームは docs/slo.md の SLO に合わせる。通知先は SNS（メール、または Datadog / PagerDuty 連携）
resource "aws_sns_topic" "alarms" {
  name = "${local.name}-alarms"
}

resource "aws_sns_topic_subscription" "email" {
  count = var.alarm_email == "" ? 0 : 1

  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

locals {
  alb_dimensions = { LoadBalancer = aws_lb.main.arn_suffix }
  tg_dimensions  = { LoadBalancer = aws_lb.main.arn_suffix, TargetGroup = aws_lb_target_group.web.arn_suffix }
}

# 可用性 SLO（99.5%）: 5 分間で 5xx の割合が 2% を超えたら通知（エラーバジェットの急速な消費）
resource "aws_cloudwatch_metric_alarm" "alb_5xx_rate" {
  alarm_name          = "${local.name}-alb-5xx-rate"
  alarm_description   = "Share of 5xx responses over 2% for 10 minutes (docs/slo.md)"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 2
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]

  metric_query {
    id          = "rate"
    expression  = "100 * (FILL(e5xx, 0) + FILL(t5xx, 0)) / FILL(req, 1)"
    label       = "5xx rate (%)"
    return_data = true
  }

  metric_query {
    id = "e5xx"
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "HTTPCode_ELB_5XX_Count"
      dimensions  = local.alb_dimensions
      period      = 300
      stat        = "Sum"
    }
  }

  metric_query {
    id = "t5xx"
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "HTTPCode_Target_5XX_Count"
      dimensions  = local.alb_dimensions
      period      = 300
      stat        = "Sum"
    }
  }

  metric_query {
    id = "req"
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "RequestCount"
      dimensions  = local.alb_dimensions
      period      = 300
      stat        = "Sum"
    }
  }
}

# レイテンシ SLO: p95 が 800ms を 15 分続けて超えたら通知
resource "aws_cloudwatch_metric_alarm" "alb_latency_p95" {
  alarm_name          = "${local.name}-alb-latency-p95"
  alarm_description   = "Target response time p95 above 800ms for 15 minutes (docs/slo.md)"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "TargetResponseTime"
  dimensions          = local.alb_dimensions
  extended_statistic  = "p95"
  period              = 300
  evaluation_periods  = 3
  threshold           = 0.8
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]
}

resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "${local.name}-unhealthy-hosts"
  alarm_description   = "At least one web task failing /up"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  dimensions          = local.tg_dimensions
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 3
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]
}

resource "aws_cloudwatch_metric_alarm" "ecs_memory" {
  alarm_name          = "${local.name}-web-memory"
  alarm_description   = "Web tasks memory above 85%"
  namespace           = "AWS/ECS"
  metric_name         = "MemoryUtilization"
  dimensions          = { ClusterName = aws_ecs_cluster.main.name, ServiceName = aws_ecs_service.web.name }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 85
  comparison_operator = "GreaterThanThreshold"
  alarm_actions       = [aws_sns_topic.alarms.arn]
}

resource "aws_cloudwatch_metric_alarm" "jobs_running" {
  alarm_name          = "${local.name}-jobs-not-running"
  alarm_description   = "No Solid Queue worker task running"
  namespace           = "ECS/ContainerInsights"
  metric_name         = "RunningTaskCount"
  dimensions          = { ClusterName = aws_ecs_cluster.main.name, ServiceName = aws_ecs_service.jobs.name }
  statistic           = "Minimum"
  period              = 300
  evaluation_periods  = 2
  threshold           = 1
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "breaching"
  alarm_actions       = [aws_sns_topic.alarms.arn]
}

resource "aws_cloudwatch_metric_alarm" "aurora_cpu" {
  alarm_name          = "${local.name}-aurora-cpu"
  alarm_description   = "Aurora CPU above 80%"
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  dimensions          = { DBClusterIdentifier = aws_rds_cluster.main.cluster_identifier }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 3
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  alarm_actions       = [aws_sns_topic.alarms.arn]
}

# 上限 ACU に張り付いているなら、上限を上げるかクエリを見直す
resource "aws_cloudwatch_metric_alarm" "aurora_capacity" {
  alarm_name          = "${local.name}-aurora-acu-near-max"
  alarm_description   = "Aurora Serverless v2 capacity at 90% of max ACU"
  namespace           = "AWS/RDS"
  metric_name         = "ServerlessDatabaseCapacity"
  dimensions          = { DBClusterIdentifier = aws_rds_cluster.main.cluster_identifier }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 3
  threshold           = var.aurora_max_acu * 0.9
  comparison_operator = "GreaterThanOrEqualToThreshold"
  alarm_actions       = [aws_sns_topic.alarms.arn]
}

resource "aws_cloudwatch_metric_alarm" "redis_memory" {
  alarm_name          = "${local.name}-redis-memory"
  alarm_description   = "Redis memory usage above 80% (cache evictions will rise)"
  namespace           = "AWS/ElastiCache"
  metric_name         = "DatabaseMemoryUsagePercentage"
  dimensions          = { ReplicationGroupId = aws_elasticache_replication_group.main.id }
  statistic           = "Maximum"
  period              = 300
  evaluation_periods  = 3
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  alarm_actions       = [aws_sns_topic.alarms.arn]
}
