# Rails の permissions_policy は旧仕様の Feature-Policy ヘッダーを出すので、Permissions-Policy は既定ヘッダーに足す。
# X-Frame-Options / X-Content-Type-Options / Referrer-Policy は Rails の既定値のまま使う。
Rails.application.config.action_dispatch.default_headers.merge!(
  "Permissions-Policy" => "camera=(), microphone=(), geolocation=(), payment=(), usb=()",
  "Cross-Origin-Opener-Policy" => "same-origin"
)
