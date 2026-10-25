# 分散トレースは OTEL_ENABLED=1 のときだけ有効にする。
# 送り先は OTLP（OTEL_EXPORTER_OTLP_ENDPOINT）。ECS では同じタスクの Datadog Agent サイドカーが OTLP を受けて Datadog APM に送る。
# 既定で無効にしているのは、ローカルや CI でエクスポーターの接続エラーを出さないため。
if ENV["OTEL_ENABLED"] == "1"
  require "opentelemetry/sdk"
  require "opentelemetry/exporter/otlp"
  require "opentelemetry/instrumentation/rails"

  OpenTelemetry::SDK.configure do |c|
    c.service_name = ENV.fetch("OTEL_SERVICE_NAME", "care-finder")
    c.service_version = ENV.fetch("APP_REVISION", "unknown")
    c.use "OpenTelemetry::Instrumentation::Rails"
  end
end
