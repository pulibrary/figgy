# frozen_string_literal: true
class PostGisService
  include GeoWorks::Derivatives::Processors::Zip

  def self.create_database
    new.create_database
  end

  def self.create_table(name:, file_path:, srid: nil)
    new(file_path: file_path, name: name).create_table
  end

  def self.delete_table(name:)
    new(name: name).delete_table
  end

  attr_reader :name, :file_path, :srid, :logger
  def initialize(name: nil, file_path: nil, srid: nil, logger: nil)
    @file_path = file_path
    @logger = logger || Logger.new(STDOUT)
    @name = name
    @srid = srid || "EPSG:4326"
  end

  def create_database
    connection(with_database: false).exec("CREATE DATABASE #{PostGis.database};")
    connection.exec("CREATE EXTENSION postgis;")
    logger.info("Created database: #{PostGis.database}")
  rescue PG::Error => e
    logger.warn("Error: #{e.message}")
  ensure
    connection&.close
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

  def delete_table
    connection.exec("DROP TABLE IF EXISTS #{name};")
    logger.info("Deleted table: #{name}")
  rescue PG::Error => e
    logger.warn("Error: #{e.message}")
  ensure
    connection&.close
  end

  private

    # Removes unzipped files
    def clean_up_zip_directory
      FileUtils.rm_rf(zip_file_directory)
    end

    def connection(with_database: true)
      if with_database
        PG.connect(dbname: PostGis.database, user: PostGis.username, password: PostGis.password)
      else
        PG.connect(user: PostGis.username, password: PostGis.password)
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
