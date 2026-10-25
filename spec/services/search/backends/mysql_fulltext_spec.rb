require "rails_helper"

RSpec.describe Search::Backends::MysqlFulltext, :committed_data do
  subject(:backend) { described_class.new }

  it_behaves_like "a facility search backend"

  it "文書の索引は持たない（MySQL の索引はトランザクションで更新される）" do
    expect(backend.indexes_documents?).to be false
    expect(backend.index(build(:facility))).to be_nil
    expect(backend.remove(1)).to be_nil
  end

  it "引用符などの演算子を含むキーワードでも SQL エラーにならない" do
    criteria = Search::Criteria.new(keyword: %("ひまわり" +-*<>()~@))
    expect { backend.search(criteria.sanitize!) }.not_to raise_error
  end
end
