module Geocoding
  # 緯度経度の値オブジェクト。距離は球面三角法（haversine）で求める。
  # MySQL の ST_Distance_Sphere と同じ地球半径を使い、DB 側の距離と表示がずれないようにする。
  class Point < Data.define(:latitude, :longitude)
    EARTH_RADIUS_METERS = 6_370_986.0

    def initialize(latitude:, longitude:)
      latitude = Float(latitude)
      longitude = Float(longitude)
      raise ArgumentError, "latitude out of range: #{latitude}" unless latitude.between?(-90, 90)
      raise ArgumentError, "longitude out of range: #{longitude}" unless longitude.between?(-180, 180)

      super
    end

    def distance_to(other)
      lat1 = to_rad(latitude)
      lat2 = to_rad(other.latitude)
      dlat = lat2 - lat1
      dlng = to_rad(other.longitude - longitude)
      a = Math.sin(dlat / 2)**2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dlng / 2)**2
      2 * EARTH_RADIUS_METERS * Math.asin(Math.sqrt(a))
    end

    private

    def to_rad(degrees) = degrees * Math::PI / 180
  end
end
