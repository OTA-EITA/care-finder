module Geocoding
  # config/stations.yml の駅名から座標を引く、外部 API を使わないジオコーダー。
  # 開発・テスト・CI ではこれだけで動き、本番で住所検索が要るときは GsiAddressSearch を前に足す。
  class StationDirectory
    def initialize(path: Rails.root.join("config/stations.yml"))
      @stations = YAML.load_file(path).to_h do |row|
        [ key(row.fetch("name")), Location.new(label: row.fetch("name"), point: Point.new(latitude: row.fetch("latitude"), longitude: row.fetch("longitude"))) ]
      end
    end

    def geocode(query)
      return nil if query.blank?

      @stations[key(query)]
    end

    def names = @stations.values.map(&:label)

    private

    def key(name) = Search::TextNormalizer.normalize(name).delete_suffix("駅")
  end
end
