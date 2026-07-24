source "https://rubygems.org"

ruby "3.3.5"

gem "rails", "~> 8.0.5"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"

# Frontend
gem "importmap-rails"
gem "propshaft"
gem "turbo-rails"
gem "stimulus-rails"

# Background jobs / caching (Rails defaults)
gem "solid_cache"
gem "solid_queue"

# Boot performance
gem "bootsnap", require: false

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"

  gem "brakeman", require: false

  gem "rubocop-rails-omakase", require: false

  gem "rspec-rails"
  gem "factory_bot_rails"
end

group :development do
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end
