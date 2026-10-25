require "rails_helper"

RSpec.describe Search::ElasticsearchClient do
  subject(:client) { described_class.new(url: "http://es.test:9200") }

  it "JSON を送り、JSON を受け取る" do
    stub_request(:post, "http://es.test:9200/facilities/_search")
      .with(body: { query: { match_all: {} } }.to_json, headers: { "Content-Type" => "application/json" })
      .to_return(status: 200, body: { hits: { total: { value: 0 } } }.to_json, headers: { "Content-Type" => "application/json" })

    expect(client.request(:post, "/facilities/_search", { query: { match_all: {} } })).to eq("hits" => { "total" => { "value" => 0 } })
  end

  it "bulk は NDJSON で送る" do
    stub = stub_request(:post, "http://es.test:9200/_bulk?refresh=true")
      .with(body: %({"index":{"_id":1}}\n{"a":1}\n), headers: { "Content-Type" => "application/x-ndjson" })
      .to_return(status: 200, body: { errors: false, items: [] }.to_json)

    client.bulk([ { index: { _id: 1 } }, { a: 1 } ], refresh: true)
    expect(stub).to have_been_requested
  end

  it "bulk の一部が失敗したらエラーにする" do
    stub_request(:post, "http://es.test:9200/_bulk").to_return(status: 200, body: { errors: true, items: [ { index: { error: { type: "mapper_parsing_exception" } } } ] }.to_json)
    expect { client.bulk([ { index: { _id: 1 } }, {} ]) }.to raise_error(described_class::Error, /mapper_parsing_exception/)
  end

  it "4xx/5xx は Error、許可したステータスは nil を返す" do
    stub_request(:delete, "http://es.test:9200/facilities/_doc/1").to_return(status: 404, body: "{}")
    expect(client.request(:delete, "/facilities/_doc/1", ignore: [ 404 ])).to be_nil

    stub_request(:get, "http://es.test:9200/facilities").to_return(status: 500, body: "{}")
    expect { client.request(:get, "/facilities") }.to raise_error(described_class::Error, /500/)
  end

  it "接続できないときは BackendUnavailable にする" do
    stub_request(:get, "http://es.test:9200/").to_raise(Errno::ECONNREFUSED)
    expect { client.request(:get, "/") }.to raise_error(Search::BackendUnavailable)

    stub_request(:get, "http://es.test:9200/").to_timeout
    expect { client.request(:get, "/") }.to raise_error(Search::BackendUnavailable)
  end
end
