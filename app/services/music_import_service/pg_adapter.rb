# frozen_string_literal: true

class MusicImportService::PgAdapter
  def initialize(dbhost:, dbport:, dbname:, dbuser:, dbpass:)
    @conn = PG.connect user: dbuser, password: dbpass, host: dbhost, port: dbport, dbname: dbname
  end

  # @param query [string]
  # @return array of hashes where the column names are the keys
  def execute(query:)
    @conn.exec(query).to_a
  end
end
