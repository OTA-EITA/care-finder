require "rails_helper"

RSpec.describe SearchIndexJob do
  let(:backend) { instance_double(Search::Backends::Elasticsearch, indexes_documents?: true, index: nil, remove: nil) }

  before do
    @original_backend = Search.backend
    Search.backend = backend
  end

  after { Search.backend = @original_backend }

  it "事業所があれば索引し直す" do
    facility = create(:facility)
    described_class.perform_now(facility.id)
    expect(backend).to have_received(:index).with(facility)
  end

  it "消えていれば索引から外す" do
    described_class.perform_now(0)
    expect(backend).to have_received(:remove).with(0)
  end

  it "索引を持つバックエンドなら、事業所の保存後にジョブを積む" do
    expect { create(:facility) }.to have_enqueued_job(described_class)
  end

  it "MySQL バックエンドならジョブを積まない" do
    Search.backend = Search::Backends::MysqlFulltext.new
    expect { create(:facility) }.not_to have_enqueued_job(described_class)
  end
end
