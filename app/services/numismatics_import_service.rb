# frozen_string_literal: true

class NumismaticsImportService
  attr_reader :db_adapter, :file_root, :logger
  def initialize(db_adapter:, file_root:, logger: nil)
    @db_adapter = db_adapter
    @file_root = file_root
    @logger = logger || Logger.new(STDOUT)
  end

  def ingest_accessions
    AccessionsImporter.new(db_adapter: db_adapter, logger: logger).import!
  end

  def ingest_firms
    FirmsImporter.new(db_adapter: db_adapter, logger: logger).import!
  end

  def ingest_issue(issue_number:)
    IssueImporter.new(issue_number: issue_number, db_adapter: db_adapter, file_root: file_root, logger: logger).import!
  end

  def ingest_monograms
    MonogramsImporter.new(db_adapter: db_adapter, file_root: file_root, logger: logger).import!
  end

  def issue_numbers
    issues = Issues.new(db_adapter: db_adapter)
    issues.ids
  end

  def ingest_people
    PeopleImporter.new(db_adapter: db_adapter, logger: logger).import!
  end

  def ingest_places
    PlacesImporter.new(db_adapter: db_adapter, logger: logger).import!
  end

  def ingest_references
    ReferencesImporter.new(db_adapter: db_adapter, logger: logger).import!
  end

  class BaseImporter
    def change_set_persister
      @change_set_persister ||= NumismaticReferencesController.change_set_persister
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

    def query_service
      @query_service ||= change_set_persister.query_service
    end

    def valkyrie_id(property: :replaces, value:, model:)
      return nil unless value
      results = query_service.custom_queries.find_by_property(property: property, value: value)
      results.select { |r| r.is_a? model }.map(&:id)
    end
  end

  class AccessionsImporter < BaseImporter
    attr_reader :db_adapter, :logger
    def initialize(db_adapter:, logger:)
      @db_adapter = db_adapter
      @logger = logger
    end

    def import!
      create_accessions
    end

    def create_accessions
      accession_numbers = accessions.ids
      accession_numbers.each do |number|
        attributes = accessions.base_attributes(id: number).to_h

        # Map ids from old database to the corresponding Valkyrie resource ids
        person = attributes[:person_id] ? "person-#{attributes[:person_id]}" : nil
        attributes[:person_id] = valkyrie_id(value: person, model: NumismaticPerson)
        attributes[:firm_id] = valkyrie_id(value: attributes[:firm_id], model: NumismaticFirm)

        # Add nested properties
        attributes[:numismatic_citation] = accession_citation_attributes(accession_id: attributes[:accession_number])

        new_resource(klass: NumismaticAccession, **attributes)
      end
    end

    def accessions
      @accessions ||= Accessions.new(db_adapter: db_adapter)
    end

    def accession_citations
      @accession_citations ||= AccessionCitations.new(db_adapter: db_adapter)
    end

    def accession_citation_attributes(accession_id:)
      accession_citations.attributes_by_accession(accession_id: accession_id).map do |record|
        record[:numismatic_reference_id] = valkyrie_id(value: record[:numismatic_reference_id], model: NumismaticReference)
        record.to_h
      end
    end
  end

  class FirmsImporter < BaseImporter
    attr_reader :db_adapter, :logger
    def initialize(db_adapter:, logger:)
      @db_adapter = db_adapter
      @logger = logger
    end

    def import!
      create_firms
    end

    def create_firms
      firm_numbers = firms.ids
      firm_numbers.each do |number|
        attributes = firms.base_attributes(id: number).to_h
        new_resource(klass: NumismaticFirm, **attributes)
      end
    end

    def firms
      @firms ||= Firms.new(db_adapter: db_adapter)
    end
  end

  class MonogramsImporter < BaseImporter
    attr_reader :db_adapter, :file_root, :logger
    def initialize(db_adapter:, file_root:, logger:)
      @db_adapter = db_adapter
      @file_root = Pathname.new(file_root.to_s)
      @logger = logger
    end

    def import!
      create_monograms
    end

    def create_monograms
      monogram_numbers = monograms.ids
      monogram_numbers.each do |number|
        attributes = monograms.base_attributes(id: number).to_h
        attributes[:files] = monogram_files(filename: attributes[:filename])

        new_resource(klass: NumismaticMonogram, **attributes)
      end
    end

    def monograms
      @monograms ||= Monograms.new(db_adapter: db_adapter)
    end

    def monogram_files(filename:)
      files = Dir.glob(file_root.join("**/#{filename}"))
      files.map do |file_path|
        IngestableFile.new(
          file_path: file_path,
          mime_type: "image/jpeg",
          original_filename: File.basename(file_path),
          copyable: false,
          container_attributes: {
            title: filename
          }
        )
      end
    end
  end

  class ReferencesImporter < BaseImporter
    attr_reader :db_adapter, :logger
    def initialize(db_adapter:, logger:)
      @db_adapter = db_adapter
      @logger = logger
    end

    def import!
      create_references
      link_members
    end

    def child_reference_ids(parent_number:)
      references.ids(column: "ParentRefID", value: parent_number).map do |child_id|
        valkyrie_id(value: child_id.to_s, model: NumismaticReference).first
      end.compact
    end

    def create_references
      reference_numbers = references.ids
      reference_numbers.each do |number|
        attributes = references.base_attributes(id: number).to_h
        attributes[:author_id] = link_authors(ids: attributes[:author_id])
        new_resource(klass: NumismaticReference, **attributes)
      end
    end

    def link_authors(ids:)
      ids.map do |id|
        valkyrie_id(value: id, model: NumismaticPerson).first
      end
    end

    def link_members
      query_service.find_all_of_model(model: NumismaticReference).each do |resource|
        ids = child_reference_ids(parent_number: resource.replaces.first)
        next if ids.empty?

        change_set_persister.buffer_into_index do |buffered_change_set_persister|
          change_set = DynamicChangeSet.new(resource)
          change_set.member_ids = ids
          buffered_change_set_persister.save(change_set: change_set)
        end
      end
    end

    def references
      @references ||= References.new(db_adapter: db_adapter)
    end
  end

  class PlacesImporter < BaseImporter
    attr_reader :db_adapter, :logger
    def initialize(db_adapter:, logger:)
      @db_adapter = db_adapter
      @logger = logger
    end

    def import!
      create_places
    end

    def create_places
      place_numbers = places.ids
      place_numbers.each do |number|
        attributes = places.base_attributes(id: number).to_h
        new_resource(klass: NumismaticPlace, **attributes)
      end
    end

    def places
      @places ||= Places.new(db_adapter: db_adapter)
    end
  end

  class PeopleImporter < BaseImporter
    attr_reader :db_adapter, :logger
    def initialize(db_adapter:, logger:)
      @db_adapter = db_adapter
      @logger = logger
    end

    def import!
      create_people
    end

    def create_people
      person_numbers = people.ids
      person_numbers.each do |number|
        attributes = people.base_attributes(id: number).to_h
        new_resource(klass: NumismaticPerson, **attributes)
      end
    end

    def people
      @people ||= People.new(db_adapter: db_adapter)
    end
  end

  class IssueImporter < BaseImporter
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

        # Map ids from old database to the corresponding Valkyrie resource ids
        attributes[:find_place_id] = valkyrie_id(value: attributes[:find_place_id], model: NumismaticPlace)
        attributes[:numismatic_accession_id] = valkyrie_id(value: attributes[:numismatic_accession_id], model: NumismaticAccession)

        # Add nested properties
        attributes[:numismatic_citation] = coin_citation_attributes(coin_id: attributes[:coin_number])
        attributes[:provenance] = provenance_attributes(coin_id: attributes[:coin_number])
        attributes[:loan] = loan_attributes(coin_id: attributes[:coin_number])

        resources << new_resource(klass: Coin, **attributes)
      end

      resources.map(&:id)
    end

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def create_issue(coin_ids:)
      attributes = issues.base_attributes(id: issue_number).to_h

      # Map ids from old database to the corresponding Valkyrie resource ids
      attributes[:numismatic_place_id] = valkyrie_id(value: attributes[:numismatic_place_id], model: NumismaticPlace)
      attributes[:ruler_id] = valkyrie_id(value: attributes[:ruler_id], model: NumismaticPerson)
      attributes[:master_id] = valkyrie_id(value: attributes[:master_id], model: NumismaticPerson)
      attributes[:numismatic_monogram_ids] = issue_monogram_ids(issue_id: attributes[:issue_number])

      # Add nested properties
      attributes[:numismatic_artist] = artist_attributes(issue_id: attributes[:issue_number])
      attributes[:numismatic_citation] = issue_citation_attributes(issue_id: attributes[:issue_number])
      attributes[:numismatic_note] = notes.attributes_by_issue(issue_id: attributes[:issue_number]).map(&:to_h)
      attributes[:numismatic_subject] = subjects.attributes_by_issue(issue_id: attributes[:issue_number]).map(&:to_h)
      attributes[:obverse_attribute] = numismatic_attributes.attributes_by_issue(issue_id: attributes[:issue_number], side: "obverse").map(&:to_h)
      attributes[:reverse_attribute] = numismatic_attributes.attributes_by_issue(issue_id: attributes[:issue_number], side: "reverse").map(&:to_h)

      resource = new_resource(klass: NumismaticIssue, **attributes)

      # Add child coins
      change_set_persister.buffer_into_index do |buffered_change_set_persister|
        change_set = DynamicChangeSet.new(resource)
        change_set.member_ids = coin_ids
        buffered_change_set_persister.save(change_set: change_set)
      end
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize

    def artist_attributes(issue_id:)
      artists.attributes_by_issue(issue_id: issue_id).map do |record|
        person = record[:person_id] ? "person-#{record[:person_id]}" : nil
        record[:person_id] = valkyrie_id(value: person, model: NumismaticPerson)
        record.to_h
      end
    end

    def artists
      @artists ||= Artists.new(db_adapter: db_adapter)
    end

    def coin_citation_attributes(coin_id:)
      coin_citations.attributes_by_coin(coin_id: coin_id).map do |record|
        record[:numismatic_reference_id] = valkyrie_id(value: record[:numismatic_reference_id], model: NumismaticReference)
        record.to_h
      end
    end

    def coin_citations
      @coin_citations ||= CoinCitations.new(db_adapter: db_adapter)
    end

    def coins
      @coins ||= Coins.new(db_adapter: db_adapter)
    end

    def issues
      @issues ||= Issues.new(db_adapter: db_adapter)
    end

    def issue_citation_attributes(issue_id:)
      issue_citations.attributes_by_issue(issue_id: issue_id).map do |record|
        record[:numismatic_reference_id] = valkyrie_id(value: record[:numismatic_reference_id], model: NumismaticReference)
        record.to_h
      end
    end

    def issue_citations
      @issue_citations ||= IssueCitations.new(db_adapter: db_adapter)
    end

    def issue_monogram_ids(issue_id:)
      issue_monograms.ids_by_issue(issue_id: issue_id).map do |id|
        valkyrie_id(value: id.to_s, model: NumismaticMonogram)
      end
    end

    def issue_monograms
      @issue_monograms ||= IssueMonograms.new(db_adapter: db_adapter)
    end

    def notes
      @notes ||= Notes.new(db_adapter: db_adapter)
    end

    def loan_attributes(coin_id:)
      loans.attributes_by_coin(coin_id: coin_id).map do |record|
        person = record[:person_id] ? "person-#{record[:person_id]}" : nil
        record[:person_id] = valkyrie_id(value: person, model: NumismaticPerson)
        record[:firm_id] = valkyrie_id(value: record[:firm_id], model: NumismaticFirm)
        record.to_h
      end
    end

    def loans
      @loans ||= Loans.new(db_adapter: db_adapter)
    end

    def numismatic_attributes
      @numismatic_attributes ||= NumismaticAttributes.new(db_adapter: db_adapter)
    end

    def provenance_attributes(coin_id:)
      provenances.attributes_by_coin(coin_id: coin_id).map do |record|
        person = record[:person_id] ? "person-#{record[:person_id]}" : nil
        record[:person_id] = valkyrie_id(value: person, model: NumismaticPerson)
        record[:firm_id] = valkyrie_id(value: record[:firm_id], model: NumismaticFirm)
        record.to_h
      end
    end

    def provenances
      @provenances ||= Provenances.new(db_adapter: db_adapter)
    end

    def subjects
      @subjects ||= Subjects.new(db_adapter: db_adapter)
    end
  end
end
