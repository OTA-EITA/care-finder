variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "environment" {
  description = "Environment name used in resource names (e.g. prod, stg)"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "availability_zones" {
  description = "Two or more AZs. Aurora and ElastiCache need subnets in at least two AZs"
  type        = list(string)
  default     = ["ap-northeast-1a", "ap-northeast-1c"]
}

variable "single_nat_gateway" {
  description = "Use one NAT gateway for all private subnets (cheaper, but an AZ failure stops outbound traffic)"
  type        = bool
  default     = true
}

variable "certificate_arn" {
  description = "ACM certificate ARN for the ALB HTTPS listener"
  type        = string
}

variable "app_hosts" {
  description = "Host names the app accepts (Rails config.hosts)"
  type        = list(string)
}

variable "image_tag" {
  description = "Container image tag to deploy (git SHA)"
  type        = string
}

variable "web_desired_count" {
  description = "Number of web tasks"
  type        = number
  default     = 2
}

variable "web_cpu" {
  description = "Fargate CPU units for a web task"
  type        = number
  default     = 512
}

variable "web_memory" {
  description = "Fargate memory (MiB) for a web task"
  type        = number
  default     = 1024
}

variable "aurora_min_acu" {
  description = "Aurora Serverless v2 minimum capacity"
  type        = number
  default     = 0.5
}

variable "aurora_max_acu" {
  description = "Aurora Serverless v2 maximum capacity"
  type        = number
  default     = 4
}

variable "redis_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t4g.micro"
}

variable "enable_datadog" {
  description = "Run the Datadog Agent as a sidecar and send traces via OTLP"
  type        = bool
  default     = false
}

variable "datadog_api_key_secret_arn" {
  description = "Secrets Manager ARN holding the Datadog API key (required when enable_datadog = true)"
  type        = string
  default     = ""
}

variable "alarm_email" {
  description = "E-mail address subscribed to the alarm SNS topic (empty = no subscription)"
  type        = string
  default     = ""
}

variable "waf_login_rate_limit" {
  description = "Max POST requests to /session per 5 minutes per IP before WAF blocks (Rails rate_limit is the first line)"
  type        = number
  default     = 100
}
