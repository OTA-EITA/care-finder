terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.70.0"
    }
  }

  # 実際に使うときは S3 バックエンド（ステートのロックは use_lockfile）を有効にする。
  # backend "s3" {
  #   bucket       = "care-finder-tfstate"
  #   key          = "prod/terraform.tfstate"
  #   region       = "ap-northeast-1"
  #   encrypt      = true
  #   use_lockfile = true
  # }
}
