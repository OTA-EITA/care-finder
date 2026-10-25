require "rails_helper"

RSpec.describe OpenData::Wamnet::Importer do
  let(:csv_path) { file_fixture("wamnet/csvdownload065.csv") }
  let(:importer) { described_class.new(prefectures: %w[北海道 大阪府], data_as_of: Date.new(2026, 3, 31)) }

  it "指定した都道府県の行だけを取り込む" do
    result = importer.import(csv_path, service_type: :houkago_day)

    expect(result).to have_attributes(upserted: 4, skipped: 1)
    expect(Facility.pluck(:prefecture).uniq).to contain_exactly("北海道", "大阪府")
    expect(Facility.find_by!(source_record_no: "65:Z0000000003")).to have_attributes(municipality: "札幌市中央区", open_sunday: true)
  end

  it "2回取り込んでも重複しない" do
    importer.import(csv_path, service_type: :houkago_day)
    expect { importer.import(csv_path, service_type: :houkago_day) }.not_to change(Facility, :count)
  end

  it "再取り込みでは職員が入力した項目を上書きせず、検索用テキストにも残す" do
    importer.import(csv_path, service_type: :houkago_day)
    facility = Facility.find_by!(source_record_no: "65:Z0000000001")
    feature = create(:feature, name: "運動療育")
    facility.update!(description: "体を動かす療育が中心です", pickup_available: true, features: [ feature ])
    facility.update_columns(name: "古い名前")

    importer.import(csv_path, service_type: :houkago_day)

    facility.reload
    expect(facility).to have_attributes(name: "架空のひまわりクラブ", description: "体を動かす療育が中心です", pickup_available: true)
    expect(facility.search_text).to include("運動療育", Search::TextNormalizer.normalize("体を動かす療育"))
  end

  it "取り込んだ行は検索用テキストを持つ" do
    importer.import(csv_path, service_type: :houkago_day)
    expect(Facility.where(search_text: [ nil, "" ])).to be_empty
  end
end
