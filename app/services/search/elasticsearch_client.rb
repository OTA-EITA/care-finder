require "net/http"

module Search
  # Elasticsearch / OpenSearch の REST API を呼ぶだけの薄いクライアント。
  # 公式 gem は製品チェックやメジャーバージョンの追従が必要になるため、使う API（索引作成・bulk・検索）に絞って自前で持つ。
  class ElasticsearchClient
    class Error < StandardError; end

    METHODS = {
      get: Net::HTTP::Get, post: Net::HTTP::Post, put: Net::HTTP::Put,
      delete: Net::HTTP::Delete, head: Net::HTTP::Head
    }.freeze
    NETWORK_ERRORS = [ SystemCallError, SocketError, Timeout::Error, IOError, OpenSSL::SSL::SSLError ].freeze

    def initialize(url:, open_timeout: 2, read_timeout: 10)
      @base = URI(url)
      @open_timeout = open_timeout
      @read_timeout = read_timeout
    end

    def request(method, path, body = nil, ignore: [], content_type: "application/json")
      uri = @base.dup
      uri.path, uri.query = path.split("?", 2)
      req = METHODS.fetch(method).new(uri)
      if body
        req["Content-Type"] = content_type
        req.body = body.is_a?(String) ? body : body.to_json
      end

      # Net::HTTP は冪等なメソッドを自動で再送するが、索引の作成（PUT）が二重に届くと失敗するので切る。
      # 再試行はジョブ側（SearchIndexJob の retry_on）で行う
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", max_retries: 0,
                                                     open_timeout: @open_timeout, read_timeout: @read_timeout) { |http| http.request(req) }
      status = response.code.to_i
      return nil if ignore.include?(status)
      raise Error, "#{method.upcase} #{path} returned #{status}: #{response.body.to_s.first(500)}" unless status.between?(200, 299)

      response.body.present? ? JSON.parse(response.body) : {}
    rescue *NETWORK_ERRORS => e
      raise BackendUnavailable, "#{e.class}: #{e.message}"
    end

    def bulk(lines, refresh: false)
      body = lines.map(&:to_json).join("\n") + "\n"
      result = request(:post, refresh ? "/_bulk?refresh=true" : "/_bulk", body, content_type: "application/x-ndjson")
      if result["errors"]
        reasons = result["items"].filter_map { |item| item.values.first["error"]&.fetch("type", nil) }.uniq
        raise Error, "bulk request had errors: #{reasons.join(', ')}"
      end
      result
    end
  end
end
