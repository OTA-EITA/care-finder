module Geocoding
  # 複数のジオコーダーを順に試し、最初に見つかった結果を返す
  class Chain
    attr_reader :geocoders

    def initialize(*geocoders)
      @geocoders = geocoders
    end

    def geocode(query)
      return nil if query.blank?

      geocoders.each do |geocoder|
        location = geocoder.geocode(query)
        return location if location
      end
      nil
    end
  end
end
