# Content Security Policy。外部のスクリプト・スタイル・フレームを読み込まない前提で絞る。
# React の props は data 属性の JSON で渡し、インラインスクリプトは使わない。
# Turbo のプログレスバーが差し込む <style> は csp_meta_tag の nonce で許可される。
# 本番はアセットを CloudFront（ASSET_HOST）から配るので、そのオリジンだけを追加で許す。
asset_host = ENV["ASSET_HOST"].presence

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.base_uri :self
    policy.connect_src :self
    policy.font_src :self, *asset_host
    policy.form_action :self
    policy.frame_ancestors :none
    policy.img_src :self, :data, *asset_host
    policy.object_src :none
    policy.script_src :self, *asset_host
    policy.style_src :self, *asset_host
  end

  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src style-src]
end
