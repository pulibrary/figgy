# frozen_string_literal: true
class OrangelightReindexer
  # Reindexes resources indexed into Orangelight by sending record updated messages
  # for all complete resources.
  # @param optional logger [Logger] instance of logger class
  def self.reindex_orangelight(logger: Logger.new(STDOUT))
    new(logger: logger).reindex_orangelight
  end

  attr_reader :logger, :ogm_repo_path
  def initialize(logger:)
    @logger = logger
  end

  def reindex_orangelight
    all_orangelight_resources.each do |resources|
      resources.each do |resource|
        begin
          decorator = resource.decorate
          messenger.record_updated(decorator)
          logger.info("Indexed into Orangelight: #{resource.id}")
        rescue StandardError => e
          logger.warn("Error: #{e.message}")
        end
      end
    end
  end

  private

    def all_orangelight_resources
      [
        complete_resources(model: Numismatics::Coin)
      ]
    end

    def complete_resources(model:)
      resources = query_service.find_all_of_model(model: model)
      resources.select { |r| r.state == ["complete"] }
    end

    def messenger
      @messenger ||= EventGenerator.new
    end

    def query_service
      Valkyrie.config.metadata_adapter.query_service
    end
end
