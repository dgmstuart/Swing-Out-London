# frozen_string_literal: true

source 'https://rubygems.org'

ruby '2.6.3'

gem 'rails', '5.2.3'

gem 'actionpack-action_caching' # to support pre rails-4 style action caching
gem 'audited'
gem 'bootsnap'
gem 'coffee-rails'
gem 'dalli'
gem 'geocoder'
gem 'haml-rails'
gem 'http'
gem 'jbuilder'
gem 'jquery-rails'
gem 'memcachier'
gem 'omniauth-facebook'
gem 'omniauth-rails_csrf_protection'
gem 'pg'
gem 'pry-rails'
gem 'puma'
gem 'rack-attack'
gem 'rails-observers' # to support pre rails-4 style cache sweeping
gem 'redcarpet' # Markdown
gem 'rollbar'
gem 'sassc-rails'
gem 'test-unit'
gem 'uglifier'

group :development do
  gem 'bullet'
  gem 'listen'
  gem 'rack-mini-profiler', require: false
end

group :development, :test do
  gem 'dotenv-rails'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'rb-fsevent'
  gem 'rspec-rails'
  gem 'rubocop-faker', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
end

group :test do
  gem 'capybara'
  gem 'climate_control'
  gem 'elabs_matchers'
  gem 'launchy'
  gem 'rails-controller-testing' # TODO: refactor tests so that we don't need this
  gem 'selenium-webdriver'
  gem 'shoulda-matchers'
  gem 'simplecov', require: false
  gem 'timecop'
  gem 'vcr'
  gem 'webmock'
end

group :production do
  gem 'oj' # For Rollbar
  gem 'rack-canonical-host'
end
