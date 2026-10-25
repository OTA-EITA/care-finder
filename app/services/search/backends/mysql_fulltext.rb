module Search
  module Backends
    # MySQL 8 の FULLTEXT インデックス（WITH PARSER ngram, ngram_token_size=2）で探す。
    # 2文字未満の語は ngram の索引に載らないので LIKE で補う。
    class MysqlFulltext
      NGRAM_TOKEN_SIZE = 2
      MATCH_SQL = "MATCH(facilities.search_text) AGAINST(? IN BOOLEAN MODE)".freeze
      DISTANCE_SQL = "ST_Distance_Sphere(POINT(facilities.longitude, facilities.latitude), POINT(?, ?))".freeze

      def indexes_documents? = false
      def index(_facility) = nil
      def remove(_facility_id) = nil
      def reindex_all(_scope) = nil

      def search(criteria, origin: nil)
        scope = filter(criteria)
        rows = order(scope, criteria, origin)
          .limit(criteria.per_page)
          .offset(criteria.offset)
          .pluck(:id, Arel.sql(distance_sql(origin)))

        BackendResult.new(
          ids: rows.map(&:first),
          total: scope.count,
          facets: facets(criteria),
          distances: origin ? rows.to_h.transform_values(&:to_f) : {}
        )
      end

      private

      def filter(criteria)
        scope = Facility.all
        scope = scope.where(service_type: criteria.service_types) if criteria.service_types.any?
        scope = scope.where(prefecture: criteria.prefecture) if criteria.prefecture
        scope = scope.where(municipality: criteria.municipality) if criteria.municipality
        scope = scope.where(open_saturday: true) if criteria.open_saturday
        scope = scope.where(Facility.arel_table[:open_sunday].eq(true).or(Facility.arel_table[:open_holiday].eq(true))) if criteria.open_sunday_or_holiday
        scope = scope.where(pickup_available: true) if criteria.pickup
        criteria.feature_codes.each do |code|
          scope = scope.where(id: FacilityFeature.joins(:feature).where(features: { code: }).select(:facility_id))
        end
        keyword_filter(scope, criteria.keyword)
      end

      def keyword_filter(scope, keyword)
        long_terms, short_terms = terms(keyword).partition { |t| t.length >= NGRAM_TOKEN_SIZE }
        scope = scope.where(MATCH_SQL, boolean_query(long_terms)) if long_terms.any?
        short_terms.reduce(scope) do |s, term|
          s.where("facilities.search_text LIKE ?", "%#{Facility.sanitize_sql_like(term)}%")
        end
      end

      def terms(keyword) = TextNormalizer.terms(keyword.to_s.delete('"'))

      # 各語を必須のフレーズにする: +"ひまわり" +"札幌"
      def boolean_query(terms) = terms.map { |t| %(+"#{t}") }.join(" ")

      def order(scope, criteria, origin)
        long_terms = terms(criteria.keyword).select { |t| t.length >= NGRAM_TOKEN_SIZE }

        if origin && (criteria.sort == "distance" || (criteria.sort == "relevance" && long_terms.empty?))
          scope.order(Arel.sql("facilities.latitude IS NULL"), Arel.sql(distance_sql(origin)), :id)
        elsif criteria.sort == "relevance" && long_terms.any?
          scope.order(Arel.sql(Facility.sanitize_sql_array([ "#{MATCH_SQL} DESC", boolean_query(long_terms) ])), :id)
        else
          scope.order(:name_kana, :id)
        end
      end

      def distance_sql(origin)
        return "NULL" unless origin

        Facility.sanitize_sql_array([ DISTANCE_SQL, origin.longitude.to_f, origin.latitude.to_f ])
      end

      def facets(criteria)
        current = filter(criteria)
        {
          service_types: filter(criteria.except(:service_types)).group(:service_type).count,
          prefectures: filter(criteria.except(:prefecture)).group(:prefecture).count,
          municipalities: criteria.prefecture ? filter(criteria.except(:municipality)).group(:municipality).count : {},
          features: current.joins(facility_features: :feature).group("features.code").count,
          open_saturday: current.where(open_saturday: true).count,
          open_sunday_or_holiday: current.where(Facility.arel_table[:open_sunday].eq(true).or(Facility.arel_table[:open_holiday].eq(true))).count,
          pickup: current.where(pickup_available: true).count
        }
      end
    end
  end
end
