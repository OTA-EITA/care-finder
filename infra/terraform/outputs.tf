output "alb_dns_name" {
  description = "Point the app domain (CNAME / alias) here"
  value       = aws_lb.main.dns_name
}

output "assets_cdn_domain" {
  description = "CloudFront domain used as ASSET_HOST"
  value       = aws_cloudfront_distribution.assets.domain_name
}

output "assets_bucket" {
  description = "Upload public/assets here on deploy"
  value       = aws_s3_bucket.assets.bucket
}

output "ecr_repository_url" {
  description = "Push the app image here"
  value       = aws_ecr_repository.app.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name (used for the one-off migration task)"
  value       = aws_ecs_cluster.main.name
}

output "migration_command" {
  description = "Run migrations as a one-off task before updating the services"
  value       = "aws ecs run-task --cluster ${aws_ecs_cluster.main.name} --launch-type FARGATE --task-definition ${aws_ecs_task_definition.web.family} --overrides '{\"containerOverrides\":[{\"name\":\"web\",\"command\":[\"./bin/rails\",\"db:migrate\"]}]}' --network-configuration 'awsvpcConfiguration={subnets=[${join(",", [for s in aws_subnet.private : s.id])}],securityGroups=[${aws_security_group.app.id}]}'"
}
