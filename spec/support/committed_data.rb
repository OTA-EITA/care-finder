# InnoDB の FULLTEXT インデックスはコミット時に更新されるため、トランザクション内で作ったデータは MATCH で見えない。
# 全文検索を通すテストは `:committed_data` を付けてトランザクションを使わず、終わったらテーブルを空にする。
module CommittedData
  TABLES = %w[facility_features favorites facility_memberships sessions users facilities features].freeze

  def self.clean!
    connection = ActiveRecord::Base.connection
    connection.disable_referential_integrity do
      TABLES.each { |table| connection.execute("DELETE FROM #{connection.quote_table_name(table)}") }
    end
  end
end

RSpec.configure do |config|
  config.define_derived_metadata(type: :system) { |meta| meta[:committed_data] = true }

  config.before(:context, :committed_data) { self.class.use_transactional_tests = false }
  config.after(:each, :committed_data) { CommittedData.clean! }
end
