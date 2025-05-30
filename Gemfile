# frozen_string_literal: true

ruby file: '.ruby-version'

source 'https://rubygems.org'

# Specify your gem's dependencies in runger_actions.gemspec
gemspec

group :development, :test do
  gem 'amazing_print'
  gem 'ostruct'
  gem 'pry-byebug', github: 'davidrunger/pry-byebug'
  gem 'rake', '~> 13.3', require: false
  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rake', require: false
  gem 'rubocop-rspec', require: false
  gem 'runger_style', require: false
end

group :development do
  gem 'runger_release_assistant', require: false
end

group :test do
  gem 'rspec', '~> 3.13'
  gem 'simplecov-cobertura', require: false
  gem 'simple_cov-formatter-terminal'
  gem 'sqlite3', '< 3.0.0'
end
