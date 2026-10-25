module Search
  # 画面に渡す検索結果
  Result = Data.define(:facilities, :total, :page, :per_page, :facets, :distances, :origin, :origin_not_found, :degraded) do
    def initialize(origin_not_found: false, degraded: false, **rest)
      super
    end

    def total_pages = [ (total.to_f / per_page).ceil, 1 ].max
    def next_page = page < total_pages ? page + 1 : nil
    def prev_page = page > 1 ? page - 1 : nil
    def distance_for(facility) = distances[facility.id]
    def origin_not_found? = origin_not_found
    def degraded? = degraded
  end
end
