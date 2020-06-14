# frozen_string_literal: true

require 'bundler/setup'

require 'active_actions'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with(:rspec) do |c|
    c.syntax = :expect
  end

  config.filter_run_when_matching(:focus)

  config.before(:suite) do
    # http://blog.spoolz.com/2015/02/05/create-an-in-memory-temporary-activerecord-table-for-testing/
    ActiveRecord::Migration.verbose = false # don't print migration output
    ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
    ActiveRecord::Schema.define(version: 1) do
      create_table :users do |t|
        t.text(:email)
        t.text(:phone)
      end
    end
  end
end
