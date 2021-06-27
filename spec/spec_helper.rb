# frozen_string_literal: true

require "wise_gopher"

require "database_cleaner"

require_relative "database_helper"

DatabaseCleaner.strategy = :transaction

RSpec.configure do |config|
  include DatabaseHelper

  config.before :suite do
    establish_connection # from database_helper

    create_articles_table # from database_helper
  end

  config.before do
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
