require "rails_helper"

RSpec.describe Geocoding::StationDirectory do
  subject(:directory) { described_class.new }

  it "駅名から代表点を返す" do
    location = directory.geocode("帯広駅")
    expect(location.label).to eq("帯広駅")
    expect(location.point.latitude).to be_within(0.01).of(42.92)
  end

  it "「駅」を省いても、前後に空白があっても引ける" do
    expect(directory.geocode("天王寺")&.label).to eq("天王寺駅")
    expect(directory.geocode(" 札幌駅 ")&.label).to eq("札幌駅")
  end

  it "知らない駅は nil" do
    expect(directory.geocode("存在しない駅")).to be_nil
    expect(directory.geocode("")).to be_nil
  end

  it "駅名の一覧を返す（入力補完用）" do
    expect(directory.names).to include("帯広駅", "大阪駅")
  end
end
