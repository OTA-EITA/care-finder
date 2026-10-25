class Facility < ApplicationRecord
  SOURCES = %w[wamnet sample].freeze
  SERVICE_TYPE_LABELS = {
    "houkago_day" => "放課後等デイサービス",
    "jidou_hattatsu" => "児童発達支援"
  }.freeze
  OPEN_DAYS = { weekday: "平日", saturday: "土曜", sunday: "日曜", holiday: "祝日" }.freeze
  # 職員が管理画面で編集できる項目。オープンデータの再取り込みはこれ以外の列だけを更新する
  STAFF_EDITABLE_ATTRIBUTES = %i[description pickup_available].freeze

  enum :service_type, { houkago_day: 1, jidou_hattatsu: 2 }, validate: true

  has_many :facility_features, dependent: :destroy
  has_many :features, -> { ordered }, through: :facility_features
  has_many :facility_memberships, dependent: :destroy
  has_many :staff_members, through: :facility_memberships, source: :user
  has_many :favorites, dependent: :destroy

  validates :source, inclusion: { in: SOURCES }
  validates :source_record_no, presence: true, uniqueness: { scope: :source }
  validates :name, :prefecture, :municipality, presence: true
  validates :latitude, numericality: { in: -90..90 }, allow_nil: true
  validates :longitude, numericality: { in: -180..180 }, allow_nil: true
  validates :capacity, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :description, length: { maximum: 2000 }
  # 取り込んだ URL が古い形式でも、職員が別の項目を保存できるよう変更時だけ確かめる
  validates :website_url, format: { with: %r{\Ahttps?://[^\s]+\z} }, allow_blank: true, if: :website_url_changed?

  before_validation :derive_open_days
  before_save :refresh_search_text
  after_commit :enqueue_search_index

  scope :located, -> { where.not(latitude: nil).where.not(longitude: nil) }

  def self.open_days_from_hours(hours)
    OPEN_DAYS.keys.to_h { |day| [ :"open_#{day}", hours[:"hours_#{day}"].present? ] }
  end

  # importer の upsert_all はコールバックを通らないので、同じ組み立てをクラスメソッドとして公開する
  def self.build_search_text(attributes, feature_names: [])
    parts = attributes.values_at(:name, :name_kana, :corporation_name, :prefecture, :municipality,
                                 :address_line, :description, :availability_notes)
    parts << SERVICE_TYPE_LABELS[attributes[:service_type].to_s]
    Search::TextNormalizer.normalize((parts + feature_names).compact.join(" "))
  end

  def service_type_label = SERVICE_TYPE_LABELS.fetch(service_type)

  def sample? = source == "sample"

  def full_address = [ prefecture, municipality, address_line ].compact.join

  def point
    return nil if latitude.nil? || longitude.nil?

    Geocoding::Point.new(latitude:, longitude:)
  end

  def open_day_labels
    OPEN_DAYS.filter_map { |day, label| label if public_send(:"open_#{day}") }
  end

  def managed_by?(user)
    return false if user.nil?

    facility_memberships.exists?(user:)
  end

  private

  def derive_open_days
    assign_attributes(self.class.open_days_from_hours(attributes.symbolize_keys))
  end

  def enqueue_search_index
    SearchIndexJob.perform_later(id) if Search.backend.indexes_documents?
  end

  def refresh_search_text
    self.search_text = self.class.build_search_text(attributes.symbolize_keys, feature_names: features.map(&:name))
  end
end
