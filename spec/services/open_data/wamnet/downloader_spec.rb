require "rails_helper"

RSpec.describe OpenData::Wamnet::Downloader do
  let(:cache_dir) { Pathname(Dir.mktmpdir) }
  let(:downloader) { described_class.new(snapshot: "202603", cache_dir:) }
  let(:url) { "https://www.wam.go.jp/content/files/pcpub/top/sfkopendata/202603/sfkopendata_202603_65.zip" }
  let(:zip_body) do
    Zip::OutputStream.write_buffer do |zip|
      zip.put_next_entry("csvdownload065.csv")
      zip.write(file_fixture("wamnet/csvdownload065.csv").binread)
    end.string
  end

  after { FileUtils.remove_entry(cache_dir) }

  it "サービス種別ごとの ZIP の URL を組み立てる" do
    expect(downloader.url_for(:houkago_day)).to eq(url)
    expect(downloader.url_for(:jidou_hattatsu)).to end_with("sfkopendata_202603_63.zip")
  end

  it "ZIP を取得して CSV を取り出す" do
    stub_request(:get, url).to_return(status: 200, body: zip_body, headers: { "Content-Type" => "application/zip" })

    csv = downloader.fetch(:houkago_day)

    expect(csv.basename.to_s).to eq("202603_csvdownload065.csv")
    expect(csv.read.force_encoding("UTF-8")).to include("架空のひまわりクラブ")
  end

  it "取得済みの ZIP があれば再ダウンロードしない" do
    stub = stub_request(:get, url).to_return(status: 200, body: zip_body)

    2.times { downloader.fetch(:houkago_day) }

    expect(stub).to have_been_requested.once
  end

  it "200 以外はエラーにする" do
    stub_request(:get, url).to_return(status: 404)

    expect { downloader.fetch(:houkago_day) }.to raise_error(described_class::Error, /404/)
  end

  it "ZIP に CSV がなければエラーにする" do
    empty = Zip::OutputStream.write_buffer { |zip| zip.put_next_entry("readme.txt") }.string
    stub_request(:get, url).to_return(status: 200, body: empty)

    expect { downloader.fetch(:houkago_day) }.to raise_error(described_class::Error, /CSV/)
  end

  it "スナップショットは YYYYMM のみ受け付ける" do
    expect { described_class.new(snapshot: "2026-03") }.to raise_error(ArgumentError)
  end
end
