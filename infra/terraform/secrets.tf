# 値は Terraform では持たず、作成後に CLI などで入れる（ステートに秘密を残さないため）
resource "aws_secretsmanager_secret" "secret_key_base" {
  name        = "${local.name}/secret-key-base"
  description = "Rails SECRET_KEY_BASE"
}

resource "aws_secretsmanager_secret" "smtp" {
  name        = "${local.name}/smtp"
  description = "SMTP credentials for password reset mail (JSON: username, password)"
}
