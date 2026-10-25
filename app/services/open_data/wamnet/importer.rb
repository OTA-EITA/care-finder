module OpenData
  module Wamnet
    # CSV を読み、指定した都道府県の事業所を upsert する。
    # 一意キーは「サービス種別コード:NO」。事業所番号は重複があるので使わない。
    class Importer
      Result = Data.define(:upserted, :skipped)
      BATCH_SIZE = 500
      KEY_COLUMNS = %i[source source_record_no].freeze

      def initialize(prefectures:, data_as_of:, logger: Rails.logger)
        @prefectures = Array(prefectures).to_set
        @data_as_of = data_as_of
        @logger = logger
      end

      def import(csv_path, service_type:)
        mapper = RowMapper.new(service_type:, data_as_of: @data_as_of)
        batch = {}
        upserted = 0
        skipped = 0

        CSV.foreach(csv_path, headers: true, encoding: "bom|utf-8") do |row|
          unless @prefectures.include?(mapper.prefecture_of(row))
            skipped += 1
            next
          end

          attrs = mapper.call(row)
          batch[attrs[:source_record_no]] = attrs
          if batch.size >= BATCH_SIZE
            upserted += flush(batch)
            batch = {}
          end
        end
        upserted += flush(batch)

        refresh_staff_edited_search_text
        @logger.info(event: "open_data.import", service_type:, upserted:, skipped:)
        Result.new(upserted:, skipped:)
      end

      private

      def flush(batch)
        return 0 if batch.empty?

        rows = batch.values
        Facility.upsert_all(rows, update_only: rows.first.keys - KEY_COLUMNS, record_timestamps: true)
        rows.size
      end

      # upsert は検索用テキストを公開データだけで作り直すので、職員が紹介文や支援内容を入れた事業所は組み立て直す
      def refresh_staff_edited_search_text
        edited = Facility.where(source: "wamnet")
          .where.not(description: [ nil, "" ])
          .or(Facility.where(source: "wamnet", id: FacilityFeature.select(:facility_id)))
        edited.includes(:features).find_each(&:save!)
      end
    end
  end
end
