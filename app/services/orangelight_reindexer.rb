# frozen_string_literal: true

class OrangelightReindexer
  # Reindexes resources indexed into Orangelight by sending record updated messages
  # for all complete resources.
  # @param optional logger [Logger] instance of logger class
  def self.reindex_orangelight(logger: Logger.new(STDOUT))
    new(logger: logger).reindex_orangelight
  end

  attr_reader :logger
  def initialize(logger:)
    @logger = logger
  end

  def reindex_orangelight
    # Tell OL it's going to get a lot of these; it won't commit each one
    ENV["BULK"] = "true"
    all_orangelight_resources.each do |resource|
      messenger.record_updated(resource)
      logger.info("Indexed into Orangelight: #{resource.id}")
    rescue => e
      logger.warn("Error: #{e.message}")
    end
  end

  private

    def all_orangelight_resources
      complete_resources(model: Numismatics::Coin)
    end

    def complete_resources(model:)
      query_service.custom_queries.find_by_property(
        property: :state,
        value: ["complete"],
        model: model,
        lazy: true
      )
    end

    def messenger
      @messenger ||= EventGenerator.new
    end

    def query_service
      Valkyrie.config.metadata_adapter.query_service
    end
end
