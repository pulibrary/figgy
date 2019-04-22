# frozen_string_literal: true

class NumismaticsImportService
  attr_reader :db_adapter, :file_root, :logger
  def initialize(db_adapter:, file_root:, logger: nil)
    @db_adapter = db_adapter
    @file_root = file_root
    @logger = logger || Logger.new(STDOUT)
  end

  def ingest_issue(issue_number:)
    IssueImporter.new(issue_number: issue_number, db_adapter: db_adapter, file_root: file_root, logger: logger).import!
  end

  def ingest_places
    PlacesImporter.new(db_adapter: db_adapter, logger: logger).import!
  end

  def ingest_people
    PeopleImporter.new(db_adapter: db_adapter, logger: logger).import!
  end

  class PlacesImporter
    attr_reader :db_adapter, :logger
    def initialize(db_adapter:, logger:)
      @db_adapter = db_adapter
      @logger = logger
    end

    def import!
      create_places
    end

    def change_set_persister
      @change_set_persister ||= NumismaticPlacesController.change_set_persister
    end

    def create_places
      place_numbers = places.ids
      place_numbers.each do |number|
        attributes = places.base_attributes(id: number).to_h
        new_resource(klass: NumismaticPlace, **attributes)
      end
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

    def places
      @places ||= Places.new(db_adapter: db_adapter)
    end
  end

  class PeopleImporter
    attr_reader :db_adapter, :logger
    def initialize(db_adapter:, logger:)
      @db_adapter = db_adapter
      @logger = logger
    end

    def import!
      create_people
    end

    def change_set_persister
      @change_set_persister ||= NumismaticPeopleController.change_set_persister
    end

    def create_people
      person_numbers = people.ids
      person_numbers.each do |number|
        attributes = people.base_attributes(id: number).to_h
        new_resource(klass: NumismaticPerson, **attributes)
      end
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

    def people
      @people ||= People.new(db_adapter: db_adapter)
    end
  end

  class IssueImporter
    attr_reader :issue_number, :db_adapter, :file_root, :logger
    def initialize(issue_number:, db_adapter:, file_root:, logger:)
      @issue_number = issue_number
      @db_adapter = db_adapter
      @file_root = Pathname.new(file_root.to_s)
      @logger = logger
    end

    def import!
      coin_ids = create_coins
      create_issue(coin_ids: coin_ids)
    end

    def coin_file_title(file_path:)
      basename = File.basename(file_path)
      if basename =~ /O/
        "Obverse"
      elsif basename =~ /R/
        "Reverse"
      end
    end

    def coin_files(coin_number:)
      files = Dir.glob(file_root.join("**/#{coin_number}{O,R}.*"))
      files.map do |file_path|
        IngestableFile.new(
          file_path: file_path,
          mime_type: "image/tiff",
          original_filename: File.basename(file_path),
          copyable: false,
          container_attributes: {
            title: coin_file_title(file_path: file_path)
          }
        )
      end
    end

    def create_coins
      resources = []
      coin_numbers = coins.ids(column: "IssueID", value: issue_number)
      coin_numbers.each do |number|
        attributes = coins.base_attributes(id: number).to_h
        files = coin_files(coin_number: number)
        attributes[:files] = files
        resources << new_resource(klass: Coin, **attributes)
      end

      resources.map(&:id)
    end

    def create_issue(coin_ids:)
      attributes = issues.base_attributes(id: issue_number).to_h

      # Map place id from old database to the corresponding Valkyrie NumismaticPlace id
      attributes[:numismatic_place_id] = valkyrie_place_id(place_id: attributes[:numismatic_place_id])
      attributes[:ruler_id] = valkyrie_id(value: attributes[:ruler_id], model: NumismaticPerson)
      attributes[:master_id] = valkyrie_id(value: attributes[:master_id], model: NumismaticPerson)

      # Add nested properties
      attributes[:numismatic_subject] = subjects.attributes_by_issue(issue_id: attributes[:issue_number]).map(&:to_h)

      resource = new_resource(klass: NumismaticIssue, **attributes)

      # Add child coins
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

    def subjects
      @subjects ||= Subjects.new(db_adapter: db_adapter)
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

    def valkyrie_place_id(place_id:)
      results = query_service.custom_queries.find_by_property(property: :replaces, value: place_id)
      results.select { |r| r.is_a? NumismaticPlace }.map(&:id)
    end

    def valkyrie_id(property: :replaces, value:, model:)
      return nil unless value
      results = query_service.custom_queries.find_by_property(property: property, value: value)
      results.select { |r| r.is_a? model }.map(&:id)
    end
  end
end
