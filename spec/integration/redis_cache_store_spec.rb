require "rails_helper"

# 本番と同じ Redis キャッシュで、rate_limit が使う increment と期限切れが動くことを確かめる（REDIS_URL があるときだけ）
RSpec.describe "Redis キャッシュストア" do
  let(:store) { ActiveSupport::Cache::RedisCacheStore.new(url: ENV.fetch("REDIS_URL", ""), namespace: "care-finder-test-#{SecureRandom.hex(4)}") }

  before do
    skip "REDIS_URL is not set" unless ENV["REDIS_URL"]
    WebMock.allow_net_connect!
  end

  after do
    store.clear if ENV["REDIS_URL"]
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  it "回数を数え、期限が来たら消える" do
    3.times { store.increment("rate-limit:login:203.0.113.1", 1, expires_in: 1.second) }
    expect(store.read("rate-limit:login:203.0.113.1", raw: true).to_i).to eq(3)

    sleep 1.5
    expect(store.read("rate-limit:login:203.0.113.1", raw: true)).to be_nil
  end

  it "ジオコーディング結果のような値オブジェクトを保存できる" do
    location = Geocoding::Location.new(label: "帯広駅", point: Geocoding::Point.new(latitude: 42.9176, longitude: 143.2042))
    store.write("geo", location)
    expect(store.read("geo")).to eq(location)
  end
end
