resource "aws_elasticache_subnet_group" "main" {
  name       = local.name
  subnet_ids = [for s in aws_subnet.private : s.id]
}

# Rails.cache（rate_limit の回数、ジオコーディング結果）用。消えても困らないデータだけを置く
resource "aws_elasticache_replication_group" "main" {
  replication_group_id       = local.name
  description                = "care-finder Rails cache"
  engine                     = "redis"
  engine_version             = "7.1"
  node_type                  = var.redis_node_type
  num_cache_clusters         = 2
  automatic_failover_enabled = true
  multi_az_enabled           = true
  port                       = 6379
  subnet_group_name          = aws_elasticache_subnet_group.main.name
  security_group_ids         = [aws_security_group.redis.id]
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  snapshot_retention_limit   = 0
  maintenance_window         = "sun:19:00-sun:20:00"
}
