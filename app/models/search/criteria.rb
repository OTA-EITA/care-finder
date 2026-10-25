module Search
  # 検索条件のフォームオブジェクト。画面・React の絞り込みパネル・検索バックエンドで同じ型を使う。
  # パラメーターはここで型をそろえ、許可していない値は捨てる。
  class Criteria
    include ActiveModel::Model
    include ActiveModel::Attributes

    SORTS = %w[relevance distance name].freeze
    PER_PAGE = 20
    MAX_KEYWORD_LENGTH = 100
    MAX_PAGE = 500
    PERMITTED = [ :keyword, :prefecture, :municipality, :open_saturday, :open_sunday_or_holiday, :pickup, :near, :sort, :page,
                  { service_types: [], feature_codes: [] } ].freeze

    attribute :keyword, :string
    attribute :prefecture, :string
    attribute :municipality, :string
    attribute :service_types, default: -> { [] }
    attribute :feature_codes, default: -> { [] }
    attribute :open_saturday, :boolean, default: false
    attribute :open_sunday_or_holiday, :boolean, default: false
    attribute :pickup, :boolean, default: false
    attribute :near, :string
    attribute :sort, :string, default: "relevance"
    attribute :page, :integer, default: 1

    def self.from_params(params)
      new(params.permit(*PERMITTED).to_h).tap(&:sanitize!)
    end

    def sanitize!
      self.keyword = keyword.to_s.strip.first(MAX_KEYWORD_LENGTH).presence
      self.prefecture = prefecture.to_s.strip.presence
      self.municipality = prefecture ? municipality.to_s.strip.presence : nil
      self.near = near.to_s.strip.first(50).presence
      self.service_types = Array(service_types).map(&:to_s) & Facility.service_types.keys
      self.feature_codes = Array(feature_codes).map(&:to_s).grep(/\A[a-z0-9_]{1,40}\z/).uniq
      self.sort = SORTS.include?(sort) ? sort : "relevance"
      self.page = page.to_i.clamp(1, MAX_PAGE)
      self
    end

    def per_page = PER_PAGE

    def offset = (page - 1) * PER_PAGE

    def blank?
      keyword.nil? && prefecture.nil? && service_types.empty? && feature_codes.empty? &&
        !open_saturday && !open_sunday_or_holiday && !pickup && near.nil?
    end

    # ファセットの件数は「その条件以外で絞り込んだ件数」で出す（disjunctive faceting）
    def except(*names)
      copy = dup
      copy.service_types = [] if names.include?(:service_types)
      copy.feature_codes = [] if names.include?(:feature_codes)
      copy.municipality = nil if names.include?(:municipality)
      if names.include?(:prefecture)
        copy.prefecture = nil
        copy.municipality = nil
      end
      copy
    end

    def to_query(**overrides)
      values = {
        keyword:, prefecture:, municipality:, near:,
        service_types: service_types.presence, feature_codes: feature_codes.presence,
        open_saturday: open_saturday ? "1" : nil,
        open_sunday_or_holiday: open_sunday_or_holiday ? "1" : nil,
        pickup: pickup ? "1" : nil,
        sort: sort == "relevance" ? nil : sort,
        page: page == 1 ? nil : page
      }
      values.merge(overrides).compact
    end

    def as_json(*)
      to_query.merge(service_types:, feature_codes:, sort:)
    end

    def dup
      self.class.new(attributes.deep_dup)
    end
  end
end
