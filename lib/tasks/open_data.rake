namespace :open_data do
  desc "WAM NET のオープンデータを取り込む（例: bin/rails open_data:import SNAPSHOT=202603 PREFECTURES=北海道,大阪府）"
  task import: :environment do
    snapshot = ENV.fetch("SNAPSHOT", "202603")
    prefectures = ENV.fetch("PREFECTURES", "北海道,大阪府").split(",").map(&:strip)
    service_types = ENV.fetch("SERVICE_TYPES", OpenData::Wamnet::SERVICE_CODES.keys.join(",")).split(",").map(&:to_sym)

    downloader = OpenData::Wamnet::Downloader.new(snapshot:)
    importer = OpenData::Wamnet::Importer.new(prefectures:, data_as_of: OpenData::Wamnet.snapshot_date(snapshot))

    service_types.each do |service_type|
      csv = downloader.fetch(service_type)
      result = importer.import(csv, service_type:)
      puts "#{service_type}: #{result.upserted} 件を取り込み、対象外 #{result.skipped} 件"
    end
    puts OpenData::Wamnet::ATTRIBUTION
  end
end
