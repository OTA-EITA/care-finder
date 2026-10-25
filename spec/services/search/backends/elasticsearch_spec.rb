require "rails_helper"

# ES_URL があるときだけ実際の Elasticsearch に対して契約テストを流す（CI ではサービスコンテナを使う）
RSpec.describe Search::Backends::Elasticsearch, :committed_data do
  subject(:backend) { described_class.new(client:, index_alias: "facilities_test_#{SecureRandom.hex(4)}") }

  let(:client) { Search::ElasticsearchClient.new(url: ENV.fetch("ES_URL", "http://127.0.0.1:9201")) }

  before do
    skip "ES_URL is not set" unless ENV["ES_URL"]
    WebMock.allow_net_connect!
  end

  after do
    if ENV["ES_URL"]
      # ES 8 以降はワイルドカードでの削除を受け付けないので、名前を引いてから 1 つずつ消す
      client.request(:get, "/_cat/indices/#{backend.index_alias}_*?format=json&h=index").each do |row|
        client.request(:delete, "/#{row['index']}", ignore: [ 404 ])
      end
      WebMock.disable_net_connect!(allow_localhost: true)
    end
  end

  it_behaves_like "a facility search backend"

  it "再索引ではエイリアスを新しい実体に付け替え、古い実体を消す" do
    create(:facility)
    first = backend.reindex_all(Facility.all)
    second = backend.reindex_all(Facility.all)

    aliases = client.request(:get, "/_alias/#{backend.index_alias}")
    expect(aliases.keys).to eq([ second ])
    expect(client.request(:head, "/#{first}", ignore: [ 404 ])).to be_nil
  end

  it "1件ずつの索引と削除ができる" do
    facility = create(:facility, name: "ひとつだけ")
    backend.reindex_all(Facility.none)
    backend.index(facility)
    client.request(:post, "/#{backend.index_alias}/_refresh")
    expect(backend.search(Search::Criteria.new(keyword: "ひとつ").sanitize!).ids).to eq([ facility.id ])

    backend.remove(facility.id)
    client.request(:post, "/#{backend.index_alias}/_refresh")
    expect(backend.search(Search::Criteria.new(keyword: "ひとつ").sanitize!).ids).to be_empty
  end
end
