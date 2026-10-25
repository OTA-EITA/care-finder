module Geocoding
  # ジオコーディングの結果。label は画面に「◯◯からの距離」と出すための名前
  Location = Data.define(:label, :point)
end
