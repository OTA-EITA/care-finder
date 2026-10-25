require "rails_helper"

RSpec.describe Search::Criteria do
  def criteria(params) = described_class.from_params(ActionController::Parameters.new(params))

  it "パラメーターから条件を組み立てる" do
    c = criteria(keyword: " 運動 ", prefecture: "北海道", municipality: "帯広市", service_types: %w[houkago_day],
                 open_saturday: "1", pickup: "1", feature_codes: %w[exercise], near: "帯広駅", sort: "distance", page: "2")

    expect(c).to have_attributes(keyword: "運動", prefecture: "北海道", municipality: "帯広市", service_types: %w[houkago_day],
                                 open_saturday: true, pickup: true, feature_codes: %w[exercise], near: "帯広駅", sort: "distance", page: 2)
  end

  it "未知のサービス種別・並び順・不正なページ番号は捨てる" do
    c = criteria(service_types: %w[houkago_day hacked], sort: "drop table", page: "-3")
    expect(c).to have_attributes(service_types: %w[houkago_day], sort: "relevance", page: 1)
  end

  it "市区町村だけ指定されても都道府県がなければ無視する" do
    expect(criteria(municipality: "帯広市").municipality).to be_nil
  end

  it "長すぎるキーワードは切り詰める" do
    expect(criteria(keyword: "あ" * 200).keyword.length).to eq(100)
  end

  it "検索結果のページ位置を計算する" do
    c = criteria(page: "3")
    expect(c.offset).to eq(40)
    expect(c.per_page).to eq(20)
  end

  describe "#to_query" do
    it "既定値を省いたクエリ文字列用のハッシュを返す" do
      c = criteria(keyword: "運動", open_saturday: "1")
      expect(c.to_query).to eq({ keyword: "運動", open_saturday: "1" })
    end

    it "上書きした値でページを作れる" do
      expect(criteria(keyword: "運動").to_query(page: 2)).to eq({ keyword: "運動", page: 2 })
    end
  end

  describe "#except" do
    it "指定した条件だけを外したコピーを返す" do
      c = criteria(prefecture: "北海道", service_types: %w[houkago_day])
      copy = c.except(:service_types)
      expect(copy.service_types).to eq([])
      expect(copy.prefecture).to eq("北海道")
      expect(c.service_types).to eq(%w[houkago_day])
    end
  end

  it "絞り込みがなければ blank? が true" do
    expect(criteria({})).to be_blank
    expect(criteria(keyword: "a")).not_to be_blank
  end
end
