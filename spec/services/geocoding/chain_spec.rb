require "rails_helper"

RSpec.describe Geocoding::Chain do
  let(:point) { Geocoding::Point.new(latitude: 1, longitude: 2) }
  let(:hit) { Geocoding::Location.new(label: "hit", point:) }

  it "最初に見つかった結果を返し、以降は呼ばない" do
    first = instance_double(Geocoding::StationDirectory, geocode: nil)
    second = instance_double(Geocoding::StationDirectory, geocode: hit)
    third = instance_double(Geocoding::StationDirectory)

    expect(described_class.new(first, second, third).geocode("x")).to eq(hit)
  end

  it "空の入力は nil" do
    expect(described_class.new.geocode(" ")).to be_nil
  end

  describe "Geocoding.default" do
    it "既定では駅名だけ、環境変数で国土地理院の住所検索を足す" do
      expect(Geocoding.default.geocoders.map(&:class)).to eq([ Geocoding::StationDirectory ])

      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("GEOCODER_GSI_ENABLED", "0").and_return("1")
      expect(Geocoding.default.geocoders.map(&:class)).to eq([ Geocoding::StationDirectory, Geocoding::GsiAddressSearch ])
    end
  end
end
