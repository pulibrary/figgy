# frozen_string_literal: true
class PostGisService
  def self.clean_database
    new.clean_database
  end

  def self.create_database
    new.create_database
  end

  def self.create_table(name:, file_path:, srid: nil)
    new(file_path: file_path, name: name).create_table
  end

  def self.database_exist?
    new.database_exist?
  end

  def self.delete_table(name:)
    new(name: name).delete_table
  end

  def self.table_exist?(name:)
    new(name: name).table_exist?
  end

  attr_reader :name, :file_path, :srid, :logger
  def initialize(name: nil, file_path: nil, srid: nil, logger: nil)
    @file_path = file_path
    @logger = logger || Logger.new(STDOUT)
    @name = name
    @srid = srid || "EPSG:4326"
  end

  def clean_database
    conn = connection
    conn.exec(clean_database_query)
    logger.info("Cleaned database: #{PostGis.database}")
    true
  rescue PG::Error => e
    logger.warn("Error: #{e.message}")
    false
  ensure
    conn&.close
  end

  def clean_database_query
    <<~SQL
      DO $$ DECLARE
          r RECORD;
      BEGIN
          FOR r IN (SELECT tablename
                    FROM pg_tables
                    WHERE schemaname = 'public' AND NOT tablename = 'spatial_ref_sys')
      LOOP
          EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(r.tablename) || ' CASCADE';
      END LOOP;
      END $$;
    SQL
  end

  def create_database
    conn = connection(with_database: false)
    conn.exec("CREATE DATABASE #{PostGis.database};")
    conn.close
    conn = connection
    conn.exec("CREATE EXTENSION postgis;")
    logger.info("Created database: #{PostGis.database}")
  rescue PG::Error => e
    logger.warn("Error: #{e.message}")
  ensure
    conn&.close
  end

  def create_table
    return unless filename
    _stdout, stderr, status = Open3.capture3(create_table_command)
    clean_up_zip_directory if zip_file?
    if status.success? && stderr.empty?
      logger.info("Created table: #{name}")
      return true
    else
      logger.warn("Error: #{stderr}")
      return false
    end
  end

  def create_table_command
    user_param = PostGis.username ? " user=#{PostGis.username}" : nil
    password_param = PostGis.password ? " password=#{PostGis.password}" : nil
    pg_params = "host=#{PostGis.host} port=5432 dbname=#{PostGis.database}#{user_param}#{password_param}"

    <<~EOF.delete("\n")
      env SHAPE_ENCODING= ogr2ogr --config OGR_TRUNCATE YES -q -nln #{name} -f \"PostgreSQL\" PG:\"#{pg_params}\"
       -t_srs #{srid} -preserve_fid -lco precision=NO '#{dataset_path}'
    EOF
  end

  def database_exist?
    conn = connection(with_database: false)
    result = conn.exec("SELECT datname FROM pg_catalog.pg_database WHERE datname = '#{PostGis.database}'")
    return false if result.first.nil?
    true
  rescue PG::Error => e
    logger.warn("Error: #{e.message}")
    false
  ensure
    conn&.close
  end

  def delete_table
    conn = connection
    conn.exec("DROP TABLE IF EXISTS #{name};")
    logger.info("Deleted table: #{name}")
  rescue PG::Error => e
    logger.warn("Error: #{e.message}")
  ensure
    conn&.close
  end

  def table_exist?
    conn = connection(with_database: false)
    result = conn.exec(table_exist_query)
    return false if result.first.nil?
    true
  rescue PG::Error => e
    logger.warn("Error: #{e.message}")
  ensure
    conn&.close
  end

  def table_exist_query
    <<~SQL
      SELECT 1
      FROM information_schema.tables
      WHERE table_schema = 'public'
      AND table_name = '#{name}';
    SQL
  end

  private

    # Removes unzipped files
    def clean_up_zip_directory
      FileUtils.rm_rf(zip_file_directory)
    end

    def connection(with_database: true)
      if with_database
        PG.connect(host: PostGis.host, dbname: PostGis.database, user: PostGis.username, password: PostGis.password)
      else
        PG.connect(host: PostGis.host, user: PostGis.username, password: PostGis.password)
      end
    end

    # Path to the dataset to load into PostGIS.
    # If the file is zipped, it is unzipped and the
    # path to a temporary directory is returned instead.
    def dataset_path
      @dataset_path ||= begin
                          if zip_file?
                            unzip_original_file
                          else
                            file_path
                          end
                        end
    end

    def filename
      return Pathname.new(file_path) if File.exist?(file_path)
    end

    # Uncompresses a zipped file and sets dataset_path variable to the resulting directory.
    def unzip_original_file
      system "unzip -qq -o -j #{filename} -d #{zip_file_directory}" unless File.directory?(zip_file_directory)
      zip_file_directory
    end

    # Tests if original file is a zip file
    # @return [Boolean]
    def zip_file?
      @zip_file ||= filename.extname.casecmp(".zip").zero?
    end

    # Path to directory in which to extract zip file
    # @return [String]
    def zip_file_directory
      "#{File.dirname(filename)}/#{File.basename(filename, '.zip')}_tmp"
    end
end
