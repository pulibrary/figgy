# frozen_string_literal: true

class GeoResourceReindexer
  # Reindexes GeoBlacklight by sending record updated messages
  # for all complete geo resources.
  # @param optional logger [Logger] instance of logger class
  def self.reindex_geoblacklight(logger: Logger.new($stdout))
    new(logger: logger, ogm_repo_path: nil).reindex_geoblacklight
  end

  # Reindexes GeoServer by sending derivative created messages
  # for all complete geo resources.
  # @param optional logger [Logger] instance of logger class
  def self.reindex_geoserver(logger: Logger.new($stdout))
    new(logger: logger, ogm_repo_path: nil).reindex_geoserver
  end

  # Builds an open geo metadata repository with all complete geo resources.
  # The repository contains geoblacklight documents and a layers.json file
  # that matches document identifiers with their location in the directory structure.
  # @param optional logger [Logger] instance of logger class
  # @param optional ogm_repo_path [String] path of ogm repository
  def self.reindex_ogm(logger: Logger.new($stdout), ogm_repo_path: "./tmp/edu.princeton.arks")
    new(logger: logger, ogm_repo_path: ogm_repo_path).reindex_ogm
  end

  attr_reader :logger, :ogm_repo_path
  def initialize(logger:, ogm_repo_path:)
    @logger = logger
    @ogm_repo_path = ogm_repo_path
  end

  def reindex_geoblacklight
    all_geo_resources.each do |resources|
      resources.each do |resource|
        decorator = resource.decorate
        messenger.record_updated(decorator)
        logger.info("Indexed into GeoBlacklight: #{resource.id}")
      rescue => e
        logger.warn("Error: #{e.message}")
      end
    end
  end

  def reindex_geoserver
    all_geo_resources.each do |resources|
      resources.each do |resource|
        decorator = resource.decorate
        file_set = decorator.geo_members.try(:first)
        next unless file_set
        messenger.derivatives_created(file_set)
        logger.info("Indexed into GeoServer: #{file_set.id}")
      rescue => e
        logger.warn("Error: #{e.message}")
      end
    end
  end

  def reindex_ogm
    @layers = {}
    all_geo_resources.each do |resources|
      resources.each do |resource|
        save_document(resource: resource)
        logger.info("GeoBlacklight document created: #{resource.id}")
      rescue => e
        logger.warn("Error: #{e.message}")
      end
    end
    save_layers_document(layers: @layers) unless @layers.empty?
  end

  private

    def all_geo_resources
      [
        complete_resources(model: RasterResource),
        complete_resources(model: VectorResource),
        complete_resources(model: ScannedMap)
      ]
    end

    def base_document_path(identifier:)
      id = identifier.gsub(%r(ark:/\d{5}/), "")
      id.scan(/.{1,2}/).join("/")
    end

    def complete_resources(model:)
      resources = query_service.find_all_of_model(model: model)
      resources.select { |r| r.state == ["complete"] }
    end

    def create_directory(identifier:)
      base = base_document_path(identifier: identifier)
      directory = "#{ogm_repo_path}/#{base}"
      FileUtils.mkdir_p directory
      directory
    end

    def document_has_errors?(document:)
      error = document["error"] || document[:error]
      logger.warn("Error: #{resource.id} #{document}") if error
      error ? true : false
    end

    def messenger
      EventGenerator.new
    end

    def query_service
      Valkyrie.config.metadata_adapter.query_service
    end

    def save_document(resource:)
      document = GeoDiscovery::DocumentBuilder.new(resource, GeoDiscovery::GeoblacklightDocument.new).to_hash
      return if document_has_errors?(document: document)
      directory = create_directory(identifier: resource.identifier.first)
      file_path = "#{directory}/geoblacklight.json"
      File.write(file_path, JSON.pretty_generate(document))
      identifier = resource.identifier.first
      @layers[identifier] = base_document_path(identifier: identifier)
    end

    def save_layers_document(layers:)
      path = "#{ogm_repo_path}/layers.json"
      output = JSON.pretty_generate(layers.sort.to_h)
      File.write(path, output)
    end
end
