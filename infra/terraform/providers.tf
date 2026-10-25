provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "care-finder"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
