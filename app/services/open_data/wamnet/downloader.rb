require "net/http"

module OpenData
  module Wamnet
    # 公開されている ZIP を取得し、中の CSV を tmp/open_data に展開する。
    # 同じスナップショットは再取得しない（WAM NET への負荷を避けるため）。
    class Downloader
      class Error < StandardError; end

      attr_reader :snapshot

      def initialize(snapshot:, cache_dir: Rails.root.join("tmp/open_data"))
        Wamnet.snapshot_date(snapshot) # 形式チェック
        @snapshot = snapshot
        @cache_dir = Pathname(cache_dir)
      end

      def url_for(service_type)
        code = SERVICE_CODES.fetch(service_type.to_sym)
        "#{FILE_BASE_URL}/#{snapshot}/sfkopendata_#{snapshot}_#{code}.zip"
      end

      def fetch(service_type)
        url = url_for(service_type)
        zip_path = @cache_dir.join(File.basename(URI(url).path))
        FileUtils.mkdir_p(@cache_dir)
        download(url, zip_path) unless zip_path.exist?
        extract_csv(zip_path)
      end

      private

      def download(url, path)
        uri = URI(url)
        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 120) do |http|
          response = http.request(Net::HTTP::Get.new(uri))
          raise Error, "GET #{url} returned #{response.code}" unless response.is_a?(Net::HTTPSuccess)

          File.binwrite(path, response.body)
        end
      end

      # 展開先のファイル名は basename だけを使い、ZIP 内のパスでディレクトリの外に書き出されないようにする
      def extract_csv(zip_path)
        Zip::File.open(zip_path.to_s) do |zip|
          entry = zip.entries.find { |e| e.file? && e.name.downcase.end_with?(".csv") }
          raise Error, "no CSV entry in #{zip_path.basename}" unless entry

          dest = @cache_dir.join("#{snapshot}_#{File.basename(entry.name)}")
          File.binwrite(dest, entry.get_input_stream.read) unless dest.exist?
          dest
        end
      end
    end
  end
end
