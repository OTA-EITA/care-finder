module OpenData
  # 障害福祉サービス等情報公表システム（WAM NET）のオープンデータ。
  # https://www.wam.go.jp/content/wamnet/pcpub/top/sfkopendata/
  # 利用条件は公共データ利用規約（第1.0版）。出典の記載が必要。
  module Wamnet
    INDEX_URL = "https://www.wam.go.jp/content/wamnet/pcpub/top/sfkopendata/".freeze
    FILE_BASE_URL = "https://www.wam.go.jp/content/files/pcpub/top/sfkopendata".freeze
    SERVICE_CODES = { houkago_day: "65", jidou_hattatsu: "63" }.freeze
    ATTRIBUTION = "出典：障害福祉サービス等情報公表システム（#{INDEX_URL}）のオープンデータをもとに作成".freeze

    # "202603" -> 2026-03-31（オープンデータは各月末時点のスナップショット）
    def self.snapshot_date(snapshot)
      raise ArgumentError, "snapshot must be YYYYMM: #{snapshot.inspect}" unless snapshot.to_s.match?(/\A\d{6}\z/)

      Date.new(snapshot[0, 4].to_i, snapshot[4, 2].to_i, -1)
    end
  end
end
