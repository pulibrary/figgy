# frozen_string_literal: true
RSpec.configure do |config|
  pg_adapter = Valkyrie::MetadataAdapter.find(:postgres)
  pg_db_cleaner = DatabaseCleaner[:sequel, db: pg_adapter.connection]
  ar_cleaner = DatabaseCleaner[:active_record]
  config.before(:suite) do
    pg_db_cleaner.clean_with(:deletion)
    ar_cleaner.clean_with(:deletion)
  end

  config.before(:each) do
    pg_db_cleaner.strategy = :transaction
    ar_cleaner.strategy = :transaction
  end

  config.before(:each, js: true) do
    pg_db_cleaner.strategy = :deletion
    ar_cleaner.strategy = :deletion
  end

  config.before(:each) do
    pg_db_cleaner.start
    ar_cleaner.start
  end

  config.after(:each) do
    pg_db_cleaner.clean
    ar_cleaner.clean
  end
end
