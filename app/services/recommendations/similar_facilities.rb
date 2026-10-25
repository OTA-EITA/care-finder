module Recommendations
  # 「似ている事業所」を内容ベースで選ぶ。利用履歴を使わないので、データが少ない立ち上げ期でも動き、
  # 点数の内訳をそのまま「おすすめの理由」として画面に出せる。
  #
  #   点数 = 0.35 × 同じサービス種別
  #        + 0.30 × 近さ（0km で 1、10km で 0）
  #        + 0.20 × 支援内容の重なり（Jaccard 係数）
  #        + 0.10 × 土日祝の利用できる曜日の重なり
  #        + 0.05 × どちらも送迎あり
  class SimilarFacilities
    Recommendation = Data.define(:facility, :score, :reasons, :distance)

    WEIGHTS = { service_type: 0.35, proximity: 0.30, features: 0.20, schedule: 0.10, pickup: 0.05 }.freeze
    RADIUS_METERS = 10_000
    CANDIDATE_LIMIT = 200
    WEEKEND_DAYS = { saturday: "土曜", sunday: "日曜", holiday: "祝日" }.freeze

    def self.distance_label(meters)
      meters < 1000 ? "約#{(meters / 10.0).round * 10}m" : "約#{(meters / 1000.0).round(1)}km"
    end

    def initialize(facility, limit: 5)
      @base = facility
      @limit = limit
    end

    def call
      origin = @base.point
      return [] unless origin

      candidates(origin)
        .filter_map { |candidate| score(candidate, origin) }
        .sort_by { |r| [ -r.score, r.distance, r.facility.id ] }
        .first(@limit)
    end

    private

    # 半径 10km を囲む緯度経度の範囲で先に絞り、近い順に上限件数まで読む
    def candidates(origin)
      lat_delta = RADIUS_METERS / 111_000.0
      lng_delta = RADIUS_METERS / (111_000.0 * Math.cos(origin.latitude * Math::PI / 180))
      distance_sql = Facility.sanitize_sql_array([
        "ST_Distance_Sphere(POINT(longitude, latitude), POINT(?, ?))", origin.longitude, origin.latitude
      ])

      Facility.located
        .where(prefecture: @base.prefecture)
        .where.not(id: @base.id)
        .where(latitude: (origin.latitude - lat_delta)..(origin.latitude + lat_delta))
        .where(longitude: (origin.longitude - lng_delta)..(origin.longitude + lng_delta))
        .order(Arel.sql(distance_sql))
        .limit(CANDIDATE_LIMIT)
        .includes(:features)
    end

    def score(candidate, origin)
      distance = origin.distance_to(candidate.point)
      return nil if distance > RADIUS_METERS

      total = 0.0
      reasons = []

      if candidate.service_type == @base.service_type
        total += WEIGHTS[:service_type]
        reasons << "同じ#{@base.service_type_label}"
      end

      total += WEIGHTS[:proximity] * (1 - distance / RADIUS_METERS)
      reasons << self.class.distance_label(distance)

      common = @base.features.map(&:name) & candidate.features.map(&:name)
      union = @base.features.map(&:name) | candidate.features.map(&:name)
      if common.any?
        total += WEIGHTS[:features] * common.size / union.size
        reasons << "共通の支援内容: #{common.join('、')}"
      end

      wanted = WEEKEND_DAYS.keys.select { |day| @base.public_send(:"open_#{day}") }
      matched = wanted.select { |day| candidate.public_send(:"open_#{day}") }
      if matched.any?
        total += WEIGHTS[:schedule] * matched.size / wanted.size
        reasons << "#{matched.map { WEEKEND_DAYS[_1] }.join('・')}も利用できる"
      end

      if @base.pickup_available && candidate.pickup_available
        total += WEIGHTS[:pickup]
        reasons << "送迎あり"
      end

      Recommendation.new(facility: candidate, score: total.round(4), reasons:, distance:)
    end
  end
end
