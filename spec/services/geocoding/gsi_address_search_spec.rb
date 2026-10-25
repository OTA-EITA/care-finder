require "rails_helper"

RSpec.describe Geocoding::GsiAddressSearch do
  subject(:geocoder) { described_class.new(cache: ActiveSupport::Cache::MemoryStore.new) }

  let(:endpoint) { %r{\Ahttps://msearch\.gsi\.go\.jp/address-search/AddressSearch} }
  let(:body) do
    [ { geometry: { coordinates: [ 143.1966, 42.9236 ], type: "Point" }, type: "Feature",
        properties: { addressCode: "", title: "北海道帯広市西５条南１０丁目" } } ].to_json
  end

  it "住所の先頭候補の座標を返す" do
    stub_request(:get, endpoint).with(query: { q: "帯広市西5条南10丁目" }).to_return(status: 200, body:)

    location = geocoder.geocode("帯広市西5条南10丁目")

    expect(location.label).to eq("北海道帯広市西５条南１０丁目")
    expect(location.point).to eq(Geocoding::Point.new(latitude: 42.9236, longitude: 143.1966))
  end

  it "同じ住所はキャッシュから返す" do
    stub = stub_request(:get, endpoint).with(query: hash_including({})).to_return(status: 200, body:)
    2.times { geocoder.geocode("帯広市") }
    expect(stub).to have_been_requested.once
  end

  it "候補がなければ nil" do
    stub_request(:get, endpoint).with(query: hash_including({})).to_return(status: 200, body: "[]")
    expect(geocoder.geocode("どこにもない住所")).to be_nil
  end

  it "タイムアウトやエラー応答では nil を返し検索自体は止めない" do
    stub_request(:get, endpoint).with(query: hash_including({})).to_timeout
    expect(geocoder.geocode("帯広市")).to be_nil

    stub_request(:get, endpoint).with(query: hash_including({})).to_return(status: 503)
    expect(geocoder.geocode("札幌市")).to be_nil
  end
end
