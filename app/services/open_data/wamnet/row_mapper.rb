module OpenData
  module Wamnet
    # CSV の1行を facilities テーブルの属性に変換する。
    # 職員が入力する項目（Facility::STAFF_EDITABLE_ATTRIBUTES）は返さないので、再取り込みで消えない。
    class RowMapper
      PREFECTURE_PATTERN = /\A(北海道|東京都|京都府|大阪府|.{2,3}県)/
      URL_PATTERN = %r{\Ahttps?://[^\s]+\z}
      LINE_BREAK = "（改行）".freeze

      def initialize(service_type:, data_as_of:)
        @service_type = service_type.to_s
        @code = SERVICE_CODES.fetch(service_type.to_sym)
        @data_as_of = data_as_of
      end

      def call(row)
        prefecture, municipality = split_city(row["事業所住所（市区町村）"])
        hours = {
          hours_weekday: presence(row["利用可能な時間帯（平日）"]),
          hours_saturday: presence(row["利用可能な時間帯（土曜）"]),
          hours_sunday: presence(row["利用可能な時間帯（日曜）"]),
          hours_holiday: presence(row["利用可能な時間帯（祝日）"])
        }

        attrs = {
          source: "wamnet",
          source_record_no: "#{@code}:#{row.fetch('NO（※システム内の固有の番号、連番）')}",
          data_as_of: @data_as_of,
          office_number: presence(row["事業所番号"]),
          service_type: Facility.service_types.fetch(@service_type),
          name: row.fetch("事業所の名称").to_s.strip,
          name_kana: presence(row["事業所の名称_かな"]),
          corporation_name: presence(row["法人の名称"]),
          prefecture:,
          municipality:,
          address_line: presence(row["事業所住所（番地以降）"]),
          latitude: decimal(row["事業所緯度"]),
          longitude: decimal(row["事業所経度"]),
          phone: presence(row["事業所電話番号"]),
          website_url: url(row["事業所URL"]),
          capacity: capacity(row["定員"]),
          closed_days: text(row["定休日"]),
          availability_notes: text(row["利用可能曜日特記事項（留意事項）"]),
          **hours,
          **Facility.open_days_from_hours(hours)
        }
        attrs[:search_text] = Facility.build_search_text(attrs.merge(service_type: @service_type))
        attrs
      end

      def prefecture_of(row) = split_city(row["事業所住所（市区町村）"]).first

      private

      def split_city(value)
        value = value.to_s.strip
        prefecture = value[PREFECTURE_PATTERN, 1]
        [ prefecture, prefecture ? value.delete_prefix(prefecture) : value ]
      end

      def presence(value) = value.to_s.strip.presence

      def text(value) = presence(value)&.gsub(LINE_BREAK, "\n")

      def url(value)
        value = presence(value)
        value if value&.match?(URL_PATTERN)
      end

      def decimal(value)
        BigDecimal(value.to_s)
      rescue ArgumentError
        nil
      end

      def capacity(value)
        number = Integer(value.to_s, exception: false)
        number if number&.positive?
      end
    end
  end
end
