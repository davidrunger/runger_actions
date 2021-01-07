# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in active_actions.gemspec
gemspec

group :test do
  gem 'codecov', require: false
  gem 'guard-espect', require: false, github: 'davidrunger/guard-espect'
  gem 'rspec', '~> 3.10'
  gem 'sqlite3'
end

group :development, :test do
  gem 'amazing_print'
  gem 'pry-byebug'
  gem 'rake', '~> 13.0'
  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rspec', require: false
  gem 'runger_style', github: 'davidrunger/runger_style', require: false
end
