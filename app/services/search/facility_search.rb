module Search
  # 検索のユースケース。起点の解決 → バックエンドで id を取得 → 事業所を読み込む。
  # 主バックエンド（Elasticsearch）が落ちていても、MySQL で検索を続ける。
  class FacilitySearch
    def initialize(backend: Search.backend, fallback: Backends::MysqlFulltext.new, geocoder: Geocoding.default, logger: Rails.logger)
      @backend = backend
      @fallback = fallback
      @geocoder = geocoder
      @logger = logger
    end

    def call(criteria)
      origin = criteria.near && @geocoder.geocode(criteria.near)
      raw, degraded = run(criteria, origin&.point)
      records = Facility.where(id: raw.ids).includes(:features).index_by(&:id)

      Result.new(
        facilities: raw.ids.filter_map { |id| records[id] },
        total: raw.total,
        page: criteria.page,
        per_page: criteria.per_page,
        facets: raw.facets,
        distances: raw.distances,
        origin:,
        origin_not_found: criteria.near.present? && origin.nil?,
        degraded:
      )
    end

    private

    def run(criteria, point)
      [ @backend.search(criteria, origin: point), false ]
    rescue BackendUnavailable => e
      raise if @fallback.nil? || @backend.equal?(@fallback)

      @logger.warn(event: "search.fallback", backend: @backend.class.name, error: e.message)
      [ @fallback.search(criteria, origin: point), true ]
    end
  end
end
