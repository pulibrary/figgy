# frozen_string_literal: true
namespace :figgy do
  namespace :music do
    namespace :import do
      desc "ingest a single recording"
      task recording: :environment do
        sql_serv_user = ENV["SQL_SERV_USER"]
        sql_serv_pass = ENV["SQL_SERV_PASS"]
        sql_serv_host = "ereserves.princeton.edu"
        sql_serv_port = 1433
        pg_user = ENV["PG_USER"]
        pg_pass = ENV["PG_PASS"]
        pg_host = ENV["PG_HOST"] || "localhost"
        pg_port = ENV["PG_PORT"] || 9900
        pg_dbname = ENV["PG_DB_NAME"] || "orangelight_staging"
        file_root = ENV["FILE_ROOT"]
        recording_id = ENV["RECORDING_ID"]
        unless sql_serv_user && sql_serv_pass && pg_user && pg_pass && file_root && recording_id
          abort "usage: rake music:import:recording SQL_SERV_USER=username SQL_SERV_PASS=password PG_USER=username PG_PASS=password [PG_DB_NAME=orangelight_staging] FILE_ROOT=fileroot RECORDING_ID=recording_id"
        end
        logger = Logger.new(STDOUT)
        collector = MusicImportService::RecordingCollector.new(
          sql_server_adapter: MusicImportService::TinyTdsAdapter.new(dbhost: sql_serv_host, dbport: sql_serv_port, dbuser: sql_serv_user, dbpass: sql_serv_pass),
          postgres_adapter: MusicImportService::PgAdapter.new(dbhost: pg_host, dbport: pg_port, dbname: pg_dbname, dbuser: pg_user, dbpass: pg_pass),
          logger: logger
        )
        new_collector = collector.with_recordings_query(
          collector.dependent_recordings_query([recording_id])
        )
        importer = MusicImportService.new(
          recording_collector: new_collector,
          logger: logger,
          file_root: file_root
        )
        importer.ingest_recording(new_collector.recordings.first)
      end

      desc "import a course's recordings"
      task course: :environment do
        sql_serv_user = ENV["SQL_SERV_USER"]
        sql_serv_pass = ENV["SQL_SERV_PASS"]
        sql_serv_host = "ereserves.princeton.edu"
        sql_serv_port = 1433
        pg_user = ENV["PG_USER"]
        pg_pass = ENV["PG_PASS"]
        pg_host = ENV["PG_HOST"] || "localhost"
        pg_port = ENV["PG_PORT"] || 9900
        pg_dbname = ENV["PG_DB_NAME"] || "orangelight_staging"
        file_root = ENV["FILE_ROOT"]
        course = ENV["COURSE"]
        unless sql_serv_user && sql_serv_pass && pg_user && pg_pass && file_root && course
          abort "usage: rake music:import:recording SQL_SERV_USER=username SQL_SERV_PASS=password PG_USER=username PG_PASS=password [PG_DB_NAME=orangelight_staging] FILE_ROOT=fileroot COURSE=course"
        end
        logger = Logger.new(STDOUT)
        collector = MusicImportService::RecordingCollector.new(
          sql_server_adapter: MusicImportService::TinyTdsAdapter.new(dbhost: sql_serv_host, dbport: sql_serv_port, dbuser: sql_serv_user, dbpass: sql_serv_pass),
          postgres_adapter: MusicImportService::PgAdapter.new(dbhost: pg_host, dbport: pg_port, dbname: pg_dbname, dbuser: pg_user, dbpass: pg_pass),
          logger: logger
        )
        importer = MusicImportService.new(
          recording_collector: collector,
          logger: logger,
          file_root: file_root
        )
        importer.ingest_course(course)
      end
    end

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

        logger = Logger.new(STDOUT)
        collector = MusicImportService::RecordingCollector.new(
          sql_server_adapter: MusicImportService::TinyTdsAdapter.new(dbhost: sql_serv_host, dbport: sql_serv_port, dbuser: sql_serv_user, dbpass: sql_serv_pass),
          postgres_adapter: MusicImportService::PgAdapter.new(dbhost: pg_host, dbport: pg_port, dbname: pg_dbname, dbuser: pg_user, dbpass: pg_pass),
          logger: logger
        )
        reporter = MusicImportService.new(
          recording_collector: collector,
          logger: logger,
          file_root: "/tmp"
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
end
