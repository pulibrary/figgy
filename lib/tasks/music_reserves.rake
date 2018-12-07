# frozen_string_literal: true

namespace :music do
  namespace :report do
    # Note that to run this task you need to install FreeTDS `brew install FreeTDS`
    desc "report on resolving call numbers to bib ids"
    task bibids: :environment do
      sql_serv_user = ENV["SQL_SERV_USER"]
      sql_serv_pass = ENV["SQL_SERV_PASS"]
      sql_serv_host = "ereserves.princeton.edu"
      sql_serv_port = 1433
      pg_user = ENV["PG_USER"]
      pg_pass = ENV["PG_PASS"]
      pg_host = "localhost"
      pg_port = 9900
      pg_dbname = ENV["PG_DB_NAME"] || "orangelight_staging"
      unless sql_serv_user && sql_serv_pass && pg_user && pg_pass
        abort "usage: rake music:report:bibids SQL_SERV_USER=username SQL_SERV_PASS=password PG_USER=username PG_PASS=password [PG_DB_NAME=orangelight_staging]"
      end

      reporter = MusicImportService.new(
        sql_server_adapter: MusicImportService::TinyTdsAdapter.new(dbhost: sql_serv_host, dbport: sql_serv_port, dbuser: sql_serv_user, dbpass: sql_serv_pass),
        postgres_adapter: MusicImportService::PgAdapter.new(dbhost: pg_host, dbport: pg_port, dbname: pg_dbname, dbuser: pg_user, dbpass: pg_pass),
        logger: Logger.new(STDOUT)
      )
      reporter.bibid_report
      File.open("recordings-extra-bibs-#{Time.zone.today}.csv", "w") do |f|
        f << reporter.extra_bibs_csv
      end
      File.open("recordings-zero-bibs-#{Time.zone.today}.csv", "w") do |f|
        f << reporter.zero_bibs_csv
      end
      File.open("recordings-course-names-#{Time.zone.today}.csv", "w") do |f|
        f << reporter.course_names_csv
      end
    end
  end
end
