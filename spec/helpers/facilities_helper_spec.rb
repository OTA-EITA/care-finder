require "rails_helper"

RSpec.describe FacilitiesHelper do
  describe "#pickup_label" do
    it "送迎の登録状況を 3 通りで表す" do
      expect(helper.pickup_label(build(:facility, pickup_available: true))).to eq("送迎あり")
      expect(helper.pickup_label(build(:facility, pickup_available: false))).to eq("送迎なし")
      expect(helper.pickup_label(build(:facility, pickup_available: nil))).to eq("未登録")
    end
  end

  describe "#openstreetmap_url" do
    it "座標があれば地図の URL を返す" do
      expect(helper.openstreetmap_url(build(:facility))).to start_with("https://www.openstreetmap.org/?mlat=42.9176&mlon=143.2042")
      expect(helper.openstreetmap_url(build(:facility, latitude: nil))).to be_nil
    end
  end

  describe "#external_url" do
    it "http(s) の URL だけを返す" do
      expect(helper.external_url("https://example.com/a")).to eq("https://example.com/a")
      expect(helper.external_url("javascript:alert(1)")).to be_nil
      expect(helper.external_url("http://")).to be_nil
      expect(helper.external_url("http://exa mple.com")).to be_nil
      expect(helper.external_url(nil)).to be_nil
    end
  end

  describe "#data_source_note" do
    it "オープンデータは時点を、サンプルは架空である旨を出す" do
      expect(helper.data_source_note(build(:facility, :wamnet))).to include("2026年3月31日時点")
      expect(helper.data_source_note(build(:facility, :wamnet, data_as_of: nil))).to include("取得日時点")
      expect(helper.data_source_note(build(:facility))).to include("サンプルデータ（架空）")
    end
  end
end
