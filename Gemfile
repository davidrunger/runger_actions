# frozen_string_literal: true

source 'https://rubygems.org'
ruby '3.2.0'

# Specify your gem's dependencies in active_actions.gemspec
gemspec

group :development, :test do
  gem 'amazing_print'
  gem 'pry-byebug'
  gem 'rake', '~> 13.0', require: false
  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rake', require: false
  gem 'rubocop-rspec', require: false
  gem 'runger_style', github: 'davidrunger/runger_style', require: false
end

group :development do
  gem 'release_assistant', require: false, github: 'davidrunger/release_assistant'
end

group :test do
  gem 'codecov', require: false
  gem 'rspec', '~> 3.12'
  gem 'simple_cov-formatter-terminal', github: 'davidrunger/simple_cov-formatter-terminal'
  gem 'sqlite3'
end
