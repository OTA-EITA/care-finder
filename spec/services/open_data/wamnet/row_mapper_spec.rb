require "rails_helper"

RSpec.describe OpenData::Wamnet::RowMapper do
  let(:rows) { CSV.read(file_fixture("wamnet/csvdownload065.csv"), headers: true, encoding: "bom|utf-8") }
  let(:mapper) { described_class.new(service_type: :houkago_day, data_as_of: Date.new(2026, 3, 31)) }

  it "1行を事業所の属性に変換する" do
    attrs = mapper.call(rows[0])

    expect(attrs).to include(
      source: "wamnet",
      source_record_no: "65:Z0000000001",
      office_number: "0000000001",
      service_type: Facility.service_types["houkago_day"],
      name: "架空のひまわりクラブ",
      name_kana: "かくうのひまわりくらぶ",
      corporation_name: "株式会社サンプル（架空）",
      prefecture: "北海道",
      municipality: "帯広市",
      address_line: "西１条南１丁目１−１",
      latitude: BigDecimal("42.919"),
      longitude: BigDecimal("143.2"),
      capacity: 10,
      hours_weekday: "13:00-18:00",
      hours_saturday: "10:00-16:00",
      hours_sunday: nil,
      hours_holiday: "10:00-16:00",
      open_weekday: true,
      open_saturday: true,
      open_sunday: false,
      open_holiday: true,
      closed_days: "日曜日",
      website_url: "https://example.com/",
      data_as_of: Date.new(2026, 3, 31)
    )
    expect(attrs[:search_text]).to include("ヒマワリクラブ", "帯広市", "放課後等デイサービス")
  end

  it "政令市は区まで市区町村として扱う" do
    expect(mapper.call(rows[2])).to include(prefecture: "北海道", municipality: "札幌市中央区")
    expect(mapper.call(rows[3])).to include(prefecture: "大阪府", municipality: "大阪市天王寺区")
  end

  it "http(s) 以外の URL と空の定員は nil にする" do
    expect(mapper.call(rows[1])).to include(website_url: nil, capacity: nil)
  end

  it "（改行）の文字列を改行に戻す" do
    expect(mapper.call(rows[1])[:availability_notes]).to eq("長期休暇中は\n10:00から")
  end

  it "職員が編集する項目は含めない" do
    expect(mapper.call(rows[0]).keys).not_to include(*Facility::STAFF_EDITABLE_ATTRIBUTES)
  end
end
