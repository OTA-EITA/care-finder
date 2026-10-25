require "rails_helper"

RSpec.describe Search::FacilitySearch do
  let(:geocoder) { Geocoding::StationDirectory.new }
  let(:mysql) { Search::Backends::MysqlFulltext.new }

  def criteria(**params) = Search::Criteria.from_params(ActionController::Parameters.new(params))

  it "バックエンドの id の順に事業所を読み込み、距離を付ける" do
    near = create(:facility, latitude: 42.9180, longitude: 143.2040)
    far = create(:facility, latitude: 42.9500, longitude: 143.2500)

    result = described_class.new(backend: mysql, geocoder:).call(criteria(near: "帯広駅", sort: "distance"))

    expect(result.facilities).to eq([ near, far ])
    expect(result.origin.label).to eq("帯広駅")
    expect(result.distance_for(near)).to be < result.distance_for(far)
    expect(result).not_to be_degraded
  end

  it "起点が見つからなければ距離なしで探し、その旨を返す" do
    create(:facility)

    result = described_class.new(backend: mysql, geocoder:).call(criteria(near: "知らない駅", sort: "distance"))

    expect(result.origin).to be_nil
    expect(result.origin_not_found?).to be true
    expect(result.total).to eq(1)
  end

  it "主バックエンドに接続できなければ MySQL で探し、劣化を記録する" do
    create(:facility)
    broken = instance_double(Search::Backends::Elasticsearch)
    allow(broken).to receive(:search).and_raise(Search::BackendUnavailable, "connection refused")

    result = described_class.new(backend: broken, fallback: mysql, geocoder:).call(criteria)

    expect(result).to be_degraded
    expect(result.total).to eq(1)
  end

  it "ページ数を計算する" do
    result = Search::Result.new(facilities: [], total: 41, page: 1, per_page: 20, facets: {}, distances: {}, origin: nil)
    expect(result.total_pages).to eq(3)
    expect(result.next_page).to eq(2)
    expect(result.prev_page).to be_nil
  end
end
