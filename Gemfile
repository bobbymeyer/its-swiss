source "https://rubygems.org"

gemspec

gem "rails", "~> 8.1"
gem "rake"
gem "sqlite3", ">= 2.1"
# json 3.0.0 (7 September 2026) changed the signature of JSON.parse, and
# Active Support 8.1.3.1 calls it the old way when it reads a signed cookie
# — so the session, and with it the flash, raise on every request. The lock
# is not committed here, so CI resolves the newest json and found it first.
# Below 3 until a Rails that takes it; the gem itself does not depend on json.
gem "json", "< 3"

group :development, :test do
  gem "rubocop-rails-omakase", require: false
  gem "capybara"
  gem "puma", ">= 5.0"
  gem "selenium-webdriver"
end
