# frozen_string_literal: true

class NumismaticsImportService
  attr_reader :logger, :db_adapter
  def initialize(db_adapter:, logger: nil)
    @logger = logger || Logger.new(STDOUT)
    @db_adapter = db_adapter
  end

  def ingest_issue(issue_number:)
    Importer.new(issue_number: issue_number, logger: logger, db_adapter: db_adapter).import!
  end

  class Importer
    attr_reader :issue_number, :logger, :change_set_persister, :db_adapter
    def initialize(issue_number:, logger:, change_set_persister: nil, db_adapter:)
      @issue_number = issue_number
      @logger = logger
      @change_set_persister = change_set_persister
      @db_adapter = db_adapter
    end

    def import!
      coin_ids = create_coins
      create_issue(coin_ids: coin_ids)
    end

    def create_coins
      resources = []
      coin_numbers = coins.ids(column: "IssueID", value: issue_number)
      coin_numbers.each do |number|
        attributes = coins.base_attributes(id: number).to_h
        resources << new_resource(klass: Coin, **attributes)
      end

      resources.map(&:id)
    end

    def create_issue(coin_ids:)
      attributes = issues.base_attributes(id: issue_number).to_h
      resource = new_resource(klass: NumismaticIssue, **attributes)

      change_set_persister.buffer_into_index do |buffered_change_set_persister|
        change_set = DynamicChangeSet.new(resource)
        change_set.member_ids = coin_ids
        buffered_change_set_persister.save(change_set: change_set)
      end
    end

    def change_set_persister
      @change_set_persister ||= NumismaticIssuesController.change_set_persister
    end

    def query_service
      @query_service ||= change_set_persister.query_service
    end

    def coins
      @coins ||= Coins.new(db_adapter: db_adapter)
    end

    def issues
      @issues ||= Issues.new(db_adapter: db_adapter)
    end

    def new_resource(klass:, **attributes)
      collection = attributes.delete(:collection)

      resource = klass.new

      change_set = DynamicChangeSet.new(resource)
      return unless change_set.validate(**attributes)
      change_set.member_of_collection_ids = [collection.id] if collection.try(:id)

      persisted = change_set_persister.save(change_set: change_set)
      logger.info "Created the resource #{persisted.id}"
      persisted
    end
  end
end
