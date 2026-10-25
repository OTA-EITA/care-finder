require "active_support/core_ext/integer/time"

# 本番は ECS Fargate 上で動かす前提（infra/terraform）。設定値はすべて環境変数から読む。
Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # アセットは CloudFront 経由で配信する。ファイル名にダイジェストが付くので長く持たせてよい
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}, immutable" }
  config.asset_host = ENV["ASSET_HOST"].presence

  # TLS は ALB で終端する。ALB → タスク間は HTTP だが、アプリからは HTTPS として扱う
  config.assume_ssl = true
  config.force_ssl = true
  config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # ログは標準出力に 1 リクエスト 1 行の JSON で出す（CloudWatch Logs / Datadog で集計しやすくするため）
  config.logger = ActiveSupport::Logger.new($stdout)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.silence_healthcheck_path = "/up"
  config.active_support.report_deprecations = false

  # キャッシュと rate_limit の回数は ElastiCache（Redis）に置き、複数タスクで共有する。
  # Redis が落ちてもリクエストは失敗させず、キャッシュなしで動かす（error_handler でログだけ出す）
  config.cache_store = :redis_cache_store, {
    url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"),
    namespace: "care-finder",
    connect_timeout: 1,
    read_timeout: 0.5,
    write_timeout: 0.5,
    reconnect_attempts: 1,
    error_handler: ->(method:, returning:, exception:) {
      Rails.logger.warn(event: "cache.error", method:, error: exception.class.name, message: exception.message)
    }
  }

  # ジョブは Solid Queue（Aurora 上の同じ DB）。docs/adr/0003-cache-and-queue.md
  config.active_job.queue_adapter = :solid_queue

  config.action_mailer.default_url_options = { host: ENV.fetch("APP_HOST", "care-finder.example"), protocol: "https" }
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: ENV["SMTP_ADDRESS"], port: ENV.fetch("SMTP_PORT", 587).to_i,
    user_name: ENV["SMTP_USERNAME"], password: ENV["SMTP_PASSWORD"],
    authentication: :login, enable_starttls_auto: true
  }

  config.i18n.fallbacks = true
  config.active_record.dump_schema_after_migration = false
  config.active_record.attributes_for_inspect = [ :id ]

  # ALB 以外からの Host ヘッダーを拒否する（DNS リバインディング対策）。/up は ALB のヘルスチェックが IP で来るので除く
  config.hosts = ENV.fetch("APP_HOSTS", "").split(",").map(&:strip).compact_blank
  config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
