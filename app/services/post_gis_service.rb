# frozen_string_literal: true
class PostGisService
  include GeoWorks::Derivatives::Processors::Zip

  def self.deliver(name:, file_path:, srid: nil)
    new(file_path: file_path, name: name).deliver
  end

  def self.delete(name:, srid: nil); end

  attr_reader :name, :file_path, :srid
  def initialize(name:, file_path: nil, srid: nil)
    @file_path = file_path
    @name = name
    @srid = srid || "EPSG:4326"
  end

  def deliver
    pg_params = "host=#{PostGis.host} port=5432 dbname=#{PostGis.database} user=#{PostGis.username} password=#{PostGis.password}"
    command = "env SHAPE_ENCODING= ogr2ogr --config OGR_TRUNCATE YES -q -nln #{name} -f \"PostgreSQL\" PG:\"#{pg_params}\""\
              " -t_srs #{srid} -preserve_fid -lco precision=NO '#{file_path}'"
    _stdout, _stderr, status = Open3.capture3(command)
    status.success?
  end
end
