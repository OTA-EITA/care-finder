# 検索バックエンドの契約テスト。MySQL FULLTEXT と Elasticsearch の両方が同じ結果を返すことを確かめる。
# 使う側で `backend` を定義する。文書を索引するバックエンドなら、データ作成後に reindex_all を呼ぶ。
RSpec.shared_examples "a facility search backend" do
  let(:obihiro_station) { Geocoding::Point.new(latitude: 42.9176, longitude: 143.2042) }
  let!(:exercise) { create(:feature, code: "exercise", name: "運動療育") }
  let!(:himawari) do
    create(:facility, :saturday, :pickup, name: "ひまわりクラブ", name_kana: "ひまわりくらぶ",
                                          latitude: 42.9180, longitude: 143.2040, features: [ exercise ])
  end
  let!(:sakura) do
    create(:facility, :jidou_hattatsu, :holiday, name: "さくら教室", name_kana: "さくらきょうしつ",
                                                 latitude: 42.9300, longitude: 143.2200)
  end
  let!(:sapporo) do
    create(:facility, name: "ひまわり札幌", name_kana: "ひまわりさっぽろ", municipality: "札幌市中央区",
                      latitude: 43.0620, longitude: 141.3500)
  end
  let!(:osaka) { create(:facility, :osaka, name: "あおぞらルーム", name_kana: "あおぞらるーむ") }

  before { backend.reindex_all(Facility.all) if backend.indexes_documents? }

  def search(origin: nil, **params)
    backend.search(Search::Criteria.from_params(ActionController::Parameters.new(params)), origin:)
  end

  it "条件がなければすべて返す" do
    result = search
    expect(result.total).to eq(4)
    expect(result.ids).to match_array([ himawari, sakura, sapporo, osaka ].map(&:id))
  end

  it "ひらがな・カタカナ・全角を問わずキーワードで探せる" do
    expect(search(keyword: "ひまわり").ids).to contain_exactly(himawari.id, sapporo.id)
    expect(search(keyword: "ヒマワリ").ids).to contain_exactly(himawari.id, sapporo.id)
  end

  it "複数の語はすべてを含むものに絞る" do
    expect(search(keyword: "ひまわり　札幌").ids).to eq([ sapporo.id ])
  end

  it "1文字の語でも探せる" do
    expect(search(keyword: "教").ids).to eq([ sakura.id ])
  end

  it "支援内容の名前でも探せる" do
    expect(search(keyword: "運動療育").ids).to eq([ himawari.id ])
  end

  it "サービス種別・地域・曜日・送迎・支援内容で絞り込める" do
    expect(search(service_types: %w[jidou_hattatsu]).ids).to eq([ sakura.id ])
    expect(search(prefecture: "北海道", municipality: "帯広市").ids).to contain_exactly(himawari.id, sakura.id)
    expect(search(open_saturday: "1").ids).to eq([ himawari.id ])
    expect(search(open_sunday_or_holiday: "1").ids).to eq([ sakura.id ])
    expect(search(pickup: "1").ids).to eq([ himawari.id ])
    expect(search(feature_codes: %w[exercise]).ids).to eq([ himawari.id ])
  end

  it "サービス種別の件数は、その条件を外した件数を返す" do
    facets = search(service_types: %w[houkago_day]).facets
    expect(facets[:service_types]).to eq("houkago_day" => 3, "jidou_hattatsu" => 1)
  end

  it "都道府県を選ぶと市区町村ごとの件数を返す" do
    facets = search(prefecture: "北海道").facets
    expect(facets[:prefectures]).to eq("北海道" => 3, "大阪府" => 1)
    expect(facets[:municipalities]).to eq("帯広市" => 2, "札幌市中央区" => 1)
    expect(facets[:features]).to eq("exercise" => 1)
    expect(facets.slice(:open_saturday, :open_sunday_or_holiday, :pickup)).to eq(open_saturday: 1, open_sunday_or_holiday: 1, pickup: 1)
  end

  it "起点から近い順に並べ、距離をメートルで返す" do
    result = search(sort: "distance", origin: obihiro_station)
    expect(result.ids).to eq([ himawari, sakura, sapporo, osaka ].map(&:id))
    expect(result.distances[himawari.id]).to be_within(30).of(himawari.point.distance_to(obihiro_station))
  end

  it "名前（かな）順に並べられる" do
    expect(search(sort: "name").ids).to eq([ osaka, sakura, himawari, sapporo ].map(&:id))
  end

  it "ページ外でも総件数は返す" do
    result = search(page: "2")
    expect(result.ids).to be_empty
    expect(result.total).to eq(4)
  end
end
