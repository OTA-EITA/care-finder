module Search
  module Backends
    # Elasticsearch（または OpenSearch）で探す。MySQL 版と同じ結果になるよう、
    # 正規化は Ruby 側（TextNormalizer）で済ませ、ES 側は 1〜2 文字の ngram に分けるだけにしている。
    #
    # 索引は「エイリアス + 日時付きの実体」で持ち、reindex_all は新しい実体を作ってからエイリアスを付け替える。
    class Elasticsearch
      BATCH_SIZE = 500
      TOKEN_CHARS = %w[letter digit punctuation symbol].freeze
      INDEX_DEFINITION = {
        settings: {
          index: { max_ngram_diff: 1, number_of_replicas: 0 },
          analysis: {
            tokenizer: {
              uni_bi_gram: { type: "ngram", min_gram: 1, max_gram: 2, token_chars: TOKEN_CHARS },
              bi_gram: { type: "ngram", min_gram: 2, max_gram: 2, token_chars: TOKEN_CHARS },
              uni_gram: { type: "ngram", min_gram: 1, max_gram: 1, token_chars: TOKEN_CHARS }
            },
            analyzer: {
              index_ngram: { type: "custom", tokenizer: "uni_bi_gram" },
              search_bigram: { type: "custom", tokenizer: "bi_gram" },
              search_unigram: { type: "custom", tokenizer: "uni_gram" }
            }
          }
        },
        mappings: {
          dynamic: "strict",
          properties: {
            id: { type: "long" },
            search_text: { type: "text", analyzer: "index_ngram", search_analyzer: "search_bigram" },
            name_kana: { type: "keyword" },
            service_type: { type: "keyword" },
            prefecture: { type: "keyword" },
            municipality: { type: "keyword" },
            feature_codes: { type: "keyword" },
            open_saturday: { type: "boolean" },
            open_sunday: { type: "boolean" },
            open_holiday: { type: "boolean" },
            pickup_available: { type: "boolean" },
            location: { type: "geo_point" }
          }
        }
      }.freeze

      attr_reader :index_alias

      def initialize(client:, index_alias: ENV.fetch("ES_INDEX") { "facilities_#{Rails.env}" })
        @client = client
        @index_alias = index_alias
      end

      def indexes_documents? = true

      def index(facility)
        @client.request(:put, "/#{index_alias}/_doc/#{facility.id}", document(facility))
      end

      def remove(facility_id)
        @client.request(:delete, "/#{index_alias}/_doc/#{facility_id}", ignore: [ 404 ])
      end

      def reindex_all(scope)
        new_index = "#{index_alias}_#{Time.current.utc.strftime('%Y%m%d%H%M%S%L')}"
        @client.request(:put, "/#{new_index}", INDEX_DEFINITION)
        scope.includes(:features).find_in_batches(batch_size: BATCH_SIZE) do |batch|
          @client.bulk(batch.flat_map { |f| [ { index: { _index: new_index, _id: f.id } }, document(f) ] })
        end
        @client.request(:post, "/#{new_index}/_refresh")
        swap_alias(new_index)
        new_index
      end

      def search(criteria, origin: nil)
        filters = filter_clauses(criteria)
        response = @client.request(:post, "/#{index_alias}/_search", {
          query: { bool: { must: keyword_clauses(criteria.keyword), filter: filters.values.flatten } },
          aggs: aggregations(criteria),
          sort: sort_clause(criteria, origin),
          from: criteria.offset,
          size: criteria.per_page,
          track_total_hits: true,
          _source: [ "location" ]
        })

        hits = response.dig("hits", "hits")
        BackendResult.new(
          ids: hits.map { |h| h["_id"].to_i },
          total: response.dig("hits", "total", "value"),
          facets: parse_facets(response["aggregations"], criteria),
          distances: origin ? distances(hits, origin) : {}
        )
      end

      def document(facility)
        {
          id: facility.id,
          search_text: facility.search_text,
          name_kana: facility.name_kana,
          service_type: facility.service_type,
          prefecture: facility.prefecture,
          municipality: facility.municipality,
          feature_codes: facility.features.map(&:code),
          open_saturday: facility.open_saturday,
          open_sunday: facility.open_sunday,
          open_holiday: facility.open_holiday,
          pickup_available: facility.pickup_available == true,
          location: facility.point && { lat: facility.point.latitude, lon: facility.point.longitude }
        }
      end

      private

      def swap_alias(new_index)
        current = @client.request(:get, "/_alias/#{index_alias}", ignore: [ 404 ])&.keys || []
        actions = current.map { |name| { remove: { index: name, alias: index_alias } } }
        actions << { add: { index: new_index, alias: index_alias } }
        @client.request(:post, "/_aliases", { actions: })
        current.each { |name| @client.request(:delete, "/#{name}", ignore: [ 404 ]) }
      end

      def keyword_clauses(keyword)
        TextNormalizer.terms(keyword).map do |term|
          analyzer = term.length >= 2 ? "search_bigram" : "search_unigram"
          { match: { search_text: { query: term, analyzer:, operator: "and" } } }
        end
      end

      def filter_clauses(criteria)
        clauses = {}
        clauses[:service_types] = { terms: { service_type: criteria.service_types } } if criteria.service_types.any?
        clauses[:prefecture] = { term: { prefecture: criteria.prefecture } } if criteria.prefecture
        clauses[:municipality] = { term: { municipality: criteria.municipality } } if criteria.municipality
        clauses[:open_saturday] = { term: { open_saturday: true } } if criteria.open_saturday
        clauses[:open_sunday_or_holiday] = sunday_or_holiday if criteria.open_sunday_or_holiday
        clauses[:pickup] = { term: { pickup_available: true } } if criteria.pickup
        clauses[:feature_codes] = criteria.feature_codes.map { |code| { term: { feature_codes: code } } } if criteria.feature_codes.any?
        clauses
      end

      def sunday_or_holiday
        { bool: { should: [ { term: { open_sunday: true } }, { term: { open_holiday: true } } ], minimum_should_match: 1 } }
      end

      # 検索クエリ（filter 込み）の結果に対する集計。サービス種別などは、その条件だけ外した件数を出す
      def aggregations(criteria)
        aggs = {
          features: { terms: { field: "feature_codes", size: 50 } },
          open_saturday: { filter: { term: { open_saturday: true } } },
          open_sunday_or_holiday: { filter: sunday_or_holiday },
          pickup: { filter: { term: { pickup_available: true } } },
          service_types: disjunctive(criteria, "service_type", 10, :service_types),
          prefectures: disjunctive(criteria, "prefecture", 50, :prefecture)
        }
        aggs[:municipalities] = disjunctive(criteria, "municipality", 300, :municipality) if criteria.prefecture
        aggs
      end

      # global から、外したい条件以外をかけ直して集計する
      def disjunctive(criteria, field, size, without)
        relaxed = criteria.except(without)
        {
          global: {},
          aggs: {
            scoped: {
              filter: { bool: { must: keyword_clauses(relaxed.keyword), filter: filter_clauses(relaxed).values.flatten } },
              aggs: { values: { terms: { field:, size: } } }
            }
          }
        }
      end

      def parse_facets(aggs, criteria)
        buckets = ->(agg) { agg["buckets"].to_h { |b| [ b["key"], b["doc_count"] ] } }
        {
          service_types: buckets.call(aggs.dig("service_types", "scoped", "values")),
          prefectures: buckets.call(aggs.dig("prefectures", "scoped", "values")),
          municipalities: criteria.prefecture ? buckets.call(aggs.dig("municipalities", "scoped", "values")) : {},
          features: buckets.call(aggs["features"]),
          open_saturday: aggs.dig("open_saturday", "doc_count"),
          open_sunday_or_holiday: aggs.dig("open_sunday_or_holiday", "doc_count"),
          pickup: aggs.dig("pickup", "doc_count")
        }
      end

      def sort_clause(criteria, origin)
        has_keyword = TextNormalizer.terms(criteria.keyword).any? { |t| t.length >= 2 }
        if origin && (criteria.sort == "distance" || (criteria.sort == "relevance" && !has_keyword))
          [ { _geo_distance: { location: { lat: origin.latitude, lon: origin.longitude }, order: "asc", unit: "m", distance_type: "arc" } }, { id: "asc" } ]
        elsif criteria.sort == "relevance" && has_keyword
          [ "_score", { id: "asc" } ]
        else
          [ { name_kana: { order: "asc", missing: "_first" } }, { id: "asc" } ]
        end
      end

      def distances(hits, origin)
        hits.each_with_object({}) do |hit, acc|
          location = hit.dig("_source", "location") or next
          acc[hit["_id"].to_i] = Geocoding::Point.new(latitude: location["lat"], longitude: location["lon"]).distance_to(origin)
        end
      end
    end
  end
end
