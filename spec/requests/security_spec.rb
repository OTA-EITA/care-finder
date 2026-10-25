require "rails_helper"

RSpec.describe "セキュリティ関連のヘッダーとヘルスチェック", type: :request do
  it "/up は 200 を返す" do
    get rails_health_check_path
    expect(response).to have_http_status(:ok)
  end

  it "CSP は nonce 付きで、インラインスクリプトと外部埋め込みを許さない" do
    get root_path
    csp = response.headers["Content-Security-Policy"]
    expect(csp).to include("default-src 'self'", "object-src 'none'", "frame-ancestors 'none'")
    expect(csp).to match(/script-src 'self' 'nonce-[^']+'/)
    expect(csp).not_to include("unsafe-inline")
  end

  it "Permissions-Policy でカメラ・マイク・位置情報を止める" do
    get root_path
    expect(response.headers["Permissions-Policy"]).to include("camera=()", "microphone=()", "geolocation=()")
  end

  it "参照元の送り方とフレーム埋め込みを制限する" do
    get root_path
    expect(response.headers["Referrer-Policy"]).to eq("strict-origin-when-cross-origin")
    expect(response.headers["X-Frame-Options"]).to eq("SAMEORIGIN")
  end
end
