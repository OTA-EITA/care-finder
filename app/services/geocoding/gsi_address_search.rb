require "net/http"

module Geocoding
  # 国土地理院の住所検索 API（地理院地図で使われているもの）で住所から座標を引く。
  # API キーは不要。検索を止めないよう、失敗時は例外を上げずに nil を返す。
  class GsiAddressSearch
    ENDPOINT = "https://msearch.gsi.go.jp/address-search/AddressSearch".freeze
    TIMEOUT_SECONDS = 3

    def initialize(cache: Rails.cache, logger: Rails.logger)
      @cache = cache
      @logger = logger
    end

    def geocode(query)
      query = query.to_s.strip
      return nil if query.empty?

      @cache.fetch([ "geocoding/gsi/v1", query ], expires_in: 1.day, skip_nil: true) { request(query) }
    end

    private

    def request(query)
      uri = URI(ENDPOINT)
      uri.query = URI.encode_www_form(q: query)
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: TIMEOUT_SECONDS, read_timeout: TIMEOUT_SECONDS) do |http|
        http.request(Net::HTTP::Get.new(uri))
      end
      return nil unless response.is_a?(Net::HTTPSuccess)

      first = JSON.parse(response.body).first
      return nil unless first

      lng, lat = first.dig("geometry", "coordinates")
      Location.new(label: first.dig("properties", "title"), point: Point.new(latitude: lat, longitude: lng))
    rescue Timeout::Error, SystemCallError, SocketError, OpenSSL::SSL::SSLError, JSON::ParserError, ArgumentError, TypeError => e
      @logger.warn(event: "geocoding.gsi.failed", error: e.class.name, message: e.message)
      nil
    end
  end
end
