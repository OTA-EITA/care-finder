# リクエストログを 1 行にまとめる。本番は JsonLogFormatter と組み合わせて JSON で出す
Rails.application.configure do
  config.lograge.enabled = Rails.env.production? || ENV["LOGRAGE"] == "1"
  config.lograge.formatter = Lograge::Formatters::Raw.new
  config.lograge.ignore_actions = [ "Rails::HealthController#show" ]
  config.lograge.custom_payload do |controller|
    { request_id: controller.request.request_id, user_id: Current.user&.id }
  end
  config.lograge.custom_options = lambda do |event|
    { event: "http.request", remote_ip: event.payload[:request]&.remote_ip, params: event.payload[:params]&.except("controller", "action") }.compact
  end
end

if Rails.env.production? || ENV["LOGRAGE"] == "1"
  require "json_log_formatter"
  Rails.application.config.after_initialize { Rails.logger.formatter = JsonLogFormatter.new }
end
