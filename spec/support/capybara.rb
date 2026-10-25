require "capybara/cuprite"

# システムテストは Cuprite（Chrome DevTools Protocol）で動かす。Selenium や chromedriver は要らない
Capybara.register_driver(:cuprite_ja) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    window_size: [ 1280, 900 ],
    headless: ENV.fetch("HEADLESS", "1") != "0",
    browser_options: { "accept-lang" => "ja-JP", "no-sandbox" => nil },
    process_timeout: 20,
    timeout: 10
  )
end
Capybara.default_max_wait_time = 5
Capybara.disable_animation = true

RSpec.configure do |config|
  config.before(:each, type: :system) { driven_by :cuprite_ja }
end
