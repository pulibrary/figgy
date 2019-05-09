# frozen_string_literal: true

class NumismaticsImportService::SqliteAdapter
  def initialize(db_path:)
    @conn = SQLite3::Database.new db_path
    @conn.results_as_hash = true
  end

  def execute(query:)
    @conn.execute(query)
  end
end
