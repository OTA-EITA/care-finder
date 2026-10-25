# 事業所検索。バックエンドは SEARCH_BACKEND で切り替える（docs/adr/0001-search-backend.md）。
#   mysql         : MySQL 8 の FULLTEXT（ngram パーサー）。既定
#   elasticsearch : Elasticsearch / OpenSearch。ES_URL が必要
module Search
  # バックエンドが返す生の結果。並び順どおりの id と、id => メートルの距離
  BackendResult = Data.define(:ids, :total, :facets, :distances)

  class BackendUnavailable < StandardError; end

  class << self
    attr_writer :backend

    def backend
      @backend ||= build_backend(ENV.fetch("SEARCH_BACKEND", "mysql"))
    end

    def build_backend(name)
      case name
      when "mysql" then Backends::MysqlFulltext.new
      when "elasticsearch" then Backends::Elasticsearch.new(client: ElasticsearchClient.new(url: ENV.fetch("ES_URL")))
      else raise ArgumentError, "unknown SEARCH_BACKEND: #{name}"
      end
    end
  end
end
