require "rails_helper"

RSpec.describe Facility do
  describe "validation" do
    it "ファクトリーの既定値で有効" do
      expect(build(:facility)).to be_valid
    end

    it "同じ取得元で同じレコード番号は登録できない" do
      create(:facility, source_record_no: "A1")
      expect(build(:facility, source_record_no: "A1")).not_to be_valid
    end

    it "取得元が違えば同じレコード番号でもよい" do
      create(:facility, source_record_no: "A1")
      expect(build(:facility, :wamnet, source_record_no: "A1")).to be_valid
    end

    it "未知の取得元は不可" do
      expect(build(:facility, source: "scraped")).not_to be_valid
    end

    it "未知のサービス種別は不可" do
      expect(build(:facility, service_type: "unknown")).not_to be_valid
    end

    it "紹介文は 2000 文字まで" do
      expect(build(:facility, description: "あ" * 2001)).not_to be_valid
    end

    it "URL は http(s) のみ" do
      expect(build(:facility, website_url: "javascript:alert(1)")).not_to be_valid
      expect(build(:facility, website_url: "https://example.com/")).to be_valid
    end
  end

  describe "営業曜日" do
    it "利用時間帯の有無から営業曜日を決める" do
      facility = create(:facility, :saturday, hours_sunday: nil)
      expect(facility).to have_attributes(open_weekday: true, open_saturday: true, open_sunday: false, open_holiday: false)
      expect(facility.open_day_labels).to eq(%w[平日 土曜])
    end
  end

  describe "検索用テキスト" do
    it "名称・住所・支援内容を正規化してまとめる" do
      feature = create(:feature, name: "運動療育")
      facility = create(:facility, name: "ひまわりクラブ", corporation_name: "株式会社ＡＢＣ", features: [ feature ])
      expect(facility.search_text).to include("ヒマワリクラブ", "abc", "帯広市", "運動療育", "放課後等デイサービス")
    end
  end

  describe "#full_address" do
    it "都道府県から番地までつなげる" do
      expect(build(:facility).full_address).to eq("北海道帯広市西1条南1丁目1")
    end
  end

  describe "#point" do
    it "緯度経度がなければ nil" do
      expect(build(:facility, latitude: nil).point).to be_nil
    end

    it "緯度経度があれば Point を返す" do
      expect(build(:facility).point).to eq(Geocoding::Point.new(latitude: 42.9176, longitude: 143.2042))
    end
  end

  describe "#service_type_label" do
    it "日本語のサービス種別名を返す" do
      expect(build(:facility, :jidou_hattatsu).service_type_label).to eq("児童発達支援")
    end
  end

  describe "#sample?" do
    it "サンプルデータかどうか" do
      expect(build(:facility)).to be_sample
      expect(build(:facility, :wamnet)).not_to be_sample
    end
  end

  describe "#managed_by?" do
    it "所属している職員だけ true" do
      facility = create(:facility)
      staff = create(:user, :staff, facility:)
      expect(facility.managed_by?(staff)).to be true
      expect(facility.managed_by?(create(:user))).to be false
      expect(facility.managed_by?(nil)).to be false
    end
  end
end
