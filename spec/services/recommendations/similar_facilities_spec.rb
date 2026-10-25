require "rails_helper"

RSpec.describe Recommendations::SimilarFacilities do
  let(:exercise) { create(:feature, code: "exercise", name: "運動療育") }
  let(:study) { create(:feature, code: "study", name: "学習支援") }
  let(:base) do
    create(:facility, :saturday, :pickup, latitude: 42.9176, longitude: 143.2042, features: [ exercise, study ])
  end

  def recommend(limit: 5) = described_class.new(base, limit:).call

  it "条件が重なるほど上に来て、サービス種別の一致は近さより重い" do
    twin = create(:facility, :saturday, :pickup, latitude: 42.9200, longitude: 143.2050, features: [ exercise, study ])
    other_type = create(:facility, :jidou_hattatsu, latitude: 42.9180, longitude: 143.2045)
    far_same = create(:facility, latitude: 42.9700, longitude: 143.2042)

    expect(recommend.map(&:facility)).to eq([ twin, far_same, other_type ])
  end

  it "おすすめの理由を返す" do
    create(:facility, :saturday, :pickup, latitude: 42.9200, longitude: 143.2050, features: [ exercise ])

    reasons = recommend.first.reasons
    expect(reasons).to include("同じ放課後等デイサービス", "共通の支援内容: 運動療育", "土曜も利用できる", "送迎あり")
    expect(reasons.grep(/\A約\d+(\.\d)?k?m\z/)).to be_present
  end

  it "自分自身・別の都道府県・10km より遠い事業所・座標のない事業所は出さない" do
    create(:facility, :osaka)
    create(:facility, latitude: 43.0686, longitude: 141.3507) # 札幌
    create(:facility, latitude: nil, longitude: nil)

    expect(recommend).to be_empty
  end

  it "件数の上限を守る" do
    create_list(:facility, 3, latitude: 42.9180, longitude: 143.2045)
    expect(recommend(limit: 2).size).to eq(2)
  end

  it "基準の事業所に座標がなければ空" do
    base.update!(latitude: nil, longitude: nil)
    expect(recommend).to eq([])
  end

  describe "距離の表示" do
    it "1km 未満はメートル、それ以上は km で表す" do
      expect(described_class.distance_label(850)).to eq("約850m")
      expect(described_class.distance_label(1_234)).to eq("約1.2km")
    end
  end
end
