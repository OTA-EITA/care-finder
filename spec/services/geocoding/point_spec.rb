require "rails_helper"

RSpec.describe Geocoding::Point do
  let(:obihiro) { described_class.new(latitude: 42.9176, longitude: 143.2042) }
  let(:sapporo) { described_class.new(latitude: 43.0686, longitude: 141.3507) }

  it "2点間の距離をメートルで返す（帯広駅〜札幌駅はおよそ 150km）" do
    expect(obihiro.distance_to(sapporo)).to be_within(3_000).of(152_000)
  end

  it "同じ点なら 0" do
    expect(obihiro.distance_to(obihiro)).to eq(0)
  end

  it "緯度経度の範囲外は作れない" do
    expect { described_class.new(latitude: 91, longitude: 0) }.to raise_error(ArgumentError)
  end
end
