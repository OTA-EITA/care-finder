require "json"
require "time"

# 1 行 1 JSON のログ。Hash を渡せばそのままフィールドになり、文字列は message に入る。
# OpenTelemetry が有効なら trace_id / span_id を足し、Datadog などでトレースとログをつなげられるようにする。
class JsonLogFormatter < ::Logger::Formatter
  def call(severity, time, _progname, payload)
    entry = { time: time.utc.iso8601(3), level: severity, service: "care-finder" }
    entry.merge!(payload.is_a?(Hash) ? payload : { message: payload.to_s.strip })
    entry.merge!(trace_context)
    "#{JSON.generate(entry)}\n"
  rescue JSON::GeneratorError, Encoding::UndefinedConversionError
    "#{JSON.generate(time: time.utc.iso8601(3), level: severity, message: payload.inspect)}\n"
  end

  private

  def trace_context
    return {} unless defined?(OpenTelemetry::Trace)

    context = OpenTelemetry::Trace.current_span.context
    return {} unless context.valid?

    { trace_id: context.hex_trace_id, span_id: context.hex_span_id }
  end
end
