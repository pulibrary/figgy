# frozen_string_literal: true

# these methods created for use in rake tasks and db/seeds.rb
require 'faker'

class DataSeeder
  attr_accessor :logger
  delegate :query_service, :persister, to: :metadata_adapter

  def initialize(logger = Logger.new(STDOUT))
    raise("DataSeeder is not for use in production!") if Rails.env == 'production'
    @logger = logger
  end

  def generate_dev_data(many_files:, many_members:)
    generate_resource_with_many_files(n: many_files)
    generate_resource_with_many_members(n: many_members)
    generate_scanned_map
    object_count_report
  end

  def wipe_metadata!
    Valkyrie::MetadataAdapter.adapters.each_value { |adapter| adapter.persister.wipe! }
  end

  def wipe_files!
    [Figgy.config['derivative_path'], Figgy.config['repository_path']].each do |dir_path|
      Pathname.new(dir_path).children.each(&:rmtree)
    end
  end

  def generate_resource_with_many_files(n:)
    sr = ScannedResource.new(attributes_hash.merge(title: "Multi-file resource"))
    sr = persister.save(resource: sr)
    n.times { add_file(resource: sr) }
    logger.info "Created scanned resource #{sr.id}: #{sr.title} with #{n} files"
  end

  def generate_resource_with_many_members(n:)
    parent = generate_scanned_resource(title: "Parent resource with many members")
    n.times do
      add_child_resource(child: generate_scanned_resource, parent_id: parent.id)
    end
  end

  def generate_scanned_resource(attrs = {})
    sr = ScannedResource.new(attributes_hash.merge(attrs))
    sr = persister.save(resource: sr)
    add_file(resource: sr)
    logger.info "Created scanned resource #{sr.id}: #{sr.title}"
    sr
  end

  def generate_scanned_map
    sm = ScannedMap.new(attributes_hash)
    sm = persister.save(resource: sm)
    add_file(resource: sm)
    logger.info "Created scanned map #{sm.id}: #{sm.title}"
  end

  def generate_ephemera_project(n_folders: 3)
    load_vocabs
    ep = EphemeraProject.new(title: "An Ephemera Project", slug: 'test-project')
    ep = persister.save(resource: ep)
    logger.info "Created ephemera project #{ep.id}: #{ep.title}"
    add_ephemera_fields(ep)
    box = add_ephemera_box(ep)
    add_ephemera_folders(n: n_folders, project: ep, box: box)
  end

  def load_vocabs
    to_load = [
      { file: "config/vocab/iso639-1.csv", name: "LAE Languages",
        columns: { label: "label", category: nil } },
      { file: "config/vocab/lae_areas.csv", name: "LAE Areas",
        columns: { label: "label", category: nil } },
      { file: File.join('spec', 'fixtures', 'lae_genres.csv'), name: "LAE Genres",
        columns: { label: "pul_label", category: nil } },
      { file: File.join('spec', 'fixtures', 'lae_subjects.csv'), name: "LAE Subjects",
        columns: { label: "subject", category: "category" } }
    ]
    to_load.each do |vocab|
      change_set_persister.buffer_into_index do |buffered_change_set_persister|
        IngestVocabService.new(buffered_change_set_persister, vocab[:file], vocab[:name], vocab[:columns], logger).ingest
      end
    end
  end

  def add_ephemera_fields(project)
    [
      ['1', 'LAE Languages'],
      ['2', 'LAE Areas'],
      ['3', 'LAE Areas'],
      ['4', 'LAE Genres'],
      ['5', 'LAE Subjects']
    ].each do |pair|
      # create the ephemera field
      field_change_set = DynamicChangeSet.new(EphemeraField.new)
      vocab = query_service.custom_queries.find_ephemera_vocabulary_by_label(label: pair[1])
      raise "Could not ingest the field for #{pair[0]}!" unless field_change_set.validate(field_name: [pair[0]], member_of_vocabulary_id: vocab.id)
      field_change_set.sync
      updated_field = change_set_persister.save(change_set: field_change_set)
      # add the field to the project
      add_member(parent: project, member: updated_field)
    end
  end

  def add_member(parent:, member:)
    member_change_set = DynamicChangeSet.new(member)
    member_change_set.prepopulate!
    member_change_set.append_id = parent.id
    member_change_set.sync
    change_set_persister.save(change_set: member_change_set)
    logger.info "Added #{member.class} #{member.id} to #{parent.class} #{parent.title || parent.box_number}"
  end

  def add_ephemera_box(project)
    change_set = DynamicChangeSet.new(EphemeraBox.new)
    change_set.validate(barcode: '00000000000000', box_number: '1')
    change_set.sync
    box = change_set_persister.save(change_set: change_set)
    add_member(parent: project, member: box)
    box
  end

  def add_ephemera_folders(n:, project:, box:)
    n.times do |i|
      change_set = DynamicChangeSet.new(EphemeraFolder.new)
      change_set.validate(
        barcode: '00000000000000',
        folder_number: i,
        title: Faker::Food.dish,
        language: [query_service.custom_queries.find_ephemera_term_by_label(label: 'English').id],
        genre: query_service.custom_queries.find_ephemera_term_by_label(label: 'Brochures').id,
        subject: [query_service.custom_queries.find_ephemera_term_by_label(label: 'Architecture').id],
        width: rand(50),
        height: rand(100),
        page_count: rand(600),
        description: Faker::Matz.quote
      )
      change_set.sync
      folder = change_set_persister.save(change_set: change_set)
      add_file(resource: folder)
      add_member(parent: box, member: folder)
    end
  end

  private

    def attributes_hash
      {
        title: Faker::Space.star,
        description: Faker::Matz.quote,
        rights_statement: rights_statements[rand(rights_statements.count)].value,
        files: [],
        read_groups: 'public',
        state: 'complete',
        visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
        import_metadata: false
      }
    end

    def rights_statements
      ControlledVocabulary.for(:rights_statement).all
    end

    def add_child_resource(child:, parent_id:)
      change_set = DynamicChangeSet.new(child)
      change_set.prepopulate!
      change_set.append_id = parent_id
      change_set_persister.save(change_set: change_set)
    end

    def add_file(resource:)
      change_set = DynamicChangeSet.new(resource)
      change_set.prepopulate!
      change_set.files = [IngestableFile.new(file_path: Rails.root.join('spec', 'fixtures', 'files', 'example.tif'), mime_type: "image/tiff", original_filename: "example.tif")]
      change_set_persister.save(change_set: change_set)
    end

    def object_count_report
      report = []
      db_count = query_service.find_all.count
      report << "#{db_count} total objects in metadata store"
      solr_count = query_service.find_all.count
      report << "#{solr_count} total objects in index"
      report.each do |line|
        logger.info line
      end
    end

    def metadata_adapter
      Valkyrie::MetadataAdapter.find(:indexing_persister)
    end

    def change_set_persister
      ::PlumChangeSetPersister.new(
        metadata_adapter: metadata_adapter,
        storage_adapter: Valkyrie.config.storage_adapter
      )
    end
end
