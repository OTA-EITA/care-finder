require "rails_helper"
require "json_log_formatter"

RSpec.describe JsonLogFormatter do
  let(:time) { Time.utc(2026, 10, 25, 1, 2, 3) }

  def format(payload) = JSON.parse(described_class.new.call("INFO", time, nil, payload))

  it "Hash はフィールドとして出す" do
    expect(format(event: "search.fallback", backend: "es")).to include(
      "time" => "2026-10-25T01:02:03.000Z", "level" => "INFO", "service" => "care-finder", "event" => "search.fallback", "backend" => "es"
    )
  end

  it "文字列は message に入れる" do
    expect(format("hello\n")).to include("message" => "hello")
  end

  it "1 行に収める" do
    expect(described_class.new.call("INFO", time, nil, "a\nb")).to end_with("}\n").and(satisfy { _1.count("\n") == 1 })
  end
end
