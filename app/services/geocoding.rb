module Geocoding
  # 既定は駅名だけ。GEOCODER_GSI_ENABLED=1 で国土地理院の住所検索を後ろに足す
  def self.default
    geocoders = [ StationDirectory.new ]
    geocoders << GsiAddressSearch.new if ENV.fetch("GEOCODER_GSI_ENABLED", "0") == "1"
    Chain.new(*geocoders)
  end
end
