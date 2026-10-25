module AuthenticationHelpers
  def sign_in_as(user, password: "correct-horse-battery")
    post session_path, params: { email_address: user.email_address, password: }
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
  config.before { Rails.cache.clear }
end
