resource "aws_db_subnet_group" "main" {
  name       = local.name
  subnet_ids = [for s in aws_subnet.private : s.id]
}

# 全文検索の ngram_token_size は静的パラメーターなので、クラスターのパラメーターグループで最初から 2 にしておく
resource "aws_rds_cluster_parameter_group" "main" {
  name   = local.name
  family = "aurora-mysql8.0"

  parameter {
    name         = "ngram_token_size"
    value        = "2"
    apply_method = "pending-reboot"
  }

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_0900_ai_ci"
  }

  parameter {
    name  = "time_zone"
    value = "Asia/Tokyo"
  }

  parameter {
    name  = "require_secure_transport"
    value = "ON"
  }

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "0.5"
  }
}

resource "aws_rds_cluster" "main" {
  cluster_identifier = local.name
  engine             = "aurora-mysql"
  engine_mode        = "provisioned"
  engine_version     = "8.0.mysql_aurora.3.10.0"
  database_name      = "care_finder"
  master_username    = "care_finder_admin"

  # パスワードは RDS が Secrets Manager で管理・ローテーションする
  manage_master_user_password = true

  db_subnet_group_name            = aws_db_subnet_group.main.name
  vpc_security_group_ids          = [aws_security_group.db.id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.main.name
  storage_encrypted               = true
  backup_retention_period         = 7
  preferred_backup_window         = "18:00-19:00"
  preferred_maintenance_window    = "sun:19:00-sun:20:00"
  deletion_protection             = true
  copy_tags_to_snapshot           = true
  final_snapshot_identifier       = "${local.name}-final"
  enabled_cloudwatch_logs_exports = ["error", "slowquery"]

  serverlessv2_scaling_configuration {
    min_capacity = var.aurora_min_acu
    max_capacity = var.aurora_max_acu
  }
}

# ライター 1 台 + リーダー 1 台（別 AZ）。ライター障害時はリーダーが昇格する
resource "aws_rds_cluster_instance" "main" {
  count = 2

  identifier                   = "${local.name}-${count.index}"
  cluster_identifier           = aws_rds_cluster.main.id
  instance_class               = "db.serverless"
  engine                       = aws_rds_cluster.main.engine
  engine_version               = aws_rds_cluster.main.engine_version
  availability_zone            = var.availability_zones[count.index % length(var.availability_zones)]
  performance_insights_enabled = true
  auto_minor_version_upgrade   = true
}
