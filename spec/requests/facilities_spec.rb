require "rails_helper"

RSpec.describe "事業所の検索と詳細", type: :request do
  describe "GET /facilities" do
    it "一覧と件数を表示する" do
      create(:facility, name: "ひまわりクラブ")
      create(:facility, :osaka, name: "あおぞらルーム")

      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ひまわりクラブ", "あおぞらルーム", "2件")
    end

    it "駅から近い順に並べ、距離を表示する" do
      create(:facility, name: "遠い教室", latitude: 42.95, longitude: 143.25)
      create(:facility, name: "近い教室", latitude: 42.918, longitude: 143.204)

      get facilities_path(near: "帯広駅", sort: "distance")

      expect(response.body.index("近い教室")).to be < response.body.index("遠い教室")
      expect(response.body).to include("帯広駅から約")
    end

    it "起点が見つからなければ知らせる" do
      get facilities_path(near: "存在しない駅")
      expect(response.body).to include("「存在しない駅」の場所が見つかりませんでした")
    end

    it "React の絞り込みパネルに条件と件数を JSON で渡す" do
      create(:facility)
      get facilities_path(service_types: %w[houkago_day])

      props = JSON.parse(Nokogiri::HTML(response.body).at_css("[data-react-island=SearchFilterPanel]")["data-props"])
      expect(props["initial"]["service_types"]).to eq(%w[houkago_day])
      expect(props["facets"]["service_types"]).to eq("houkago_day" => 1)
      expect(props["stations"]).to include("帯広駅")
    end

    it "検索が劣化したときは知らせる" do
      allow_any_instance_of(Search::FacilitySearch).to receive(:call).and_wrap_original do |original, criteria|
        original.call(criteria).with(degraded: true)
      end

      get facilities_path
      expect(response.body).to include("簡易検索")
    end

    it "次のページへのリンクを出す" do
      create_list(:facility, 21)
      get facilities_path
      expect(response.body).to include(facilities_path(page: 2))
    end
  end

  describe "GET /facilities?keyword=", :committed_data do
    it "キーワードで絞り込む" do
      create(:facility, name: "ひまわりクラブ")
      create(:facility, name: "さくら教室")

      get facilities_path(keyword: "ヒマワリ")

      expect(response.body).to include("ひまわりクラブ")
      expect(response.body).not_to include("さくら教室")
    end
  end

  describe "GET /facilities/:id" do
    it "詳細・似ている事業所と理由・出典を表示する" do
      facility = create(:facility, :wamnet, :saturday, name: "ひまわりクラブ", website_url: "https://example.com/")
      create(:facility, :saturday, name: "となりの教室", latitude: 42.9180, longitude: 143.2045)

      get facility_path(facility)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ひまわりクラブ", "放課後等デイサービス", "13:00-18:00", "となりの教室", "同じ放課後等デイサービス", "土曜も利用できる")
      expect(response.body).to include("障害福祉サービス等情報公表システム", "2026年3月31日時点")
      expect(response.body).to include('rel="noopener noreferrer nofollow"')
    end

    it "サンプルデータには架空である旨を表示する" do
      get facility_path(create(:facility))
      expect(response.body).to include("サンプルデータ（架空）")
    end

    it "ない事業所は 404" do
      get facility_path(id: 0)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /about" do
    it "データの出典と利用条件を表示する" do
      get about_path
      expect(response.body).to include("公共データ利用規約（第1.0版）", OpenData::Wamnet::INDEX_URL)
    end
  end
end
