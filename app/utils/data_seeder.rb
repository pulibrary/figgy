# frozen_string_literal: true

# these methods created for use in rake tasks and db/seeds.rb
require "faker"

class DataSeeder
  attr_accessor :logger
  delegate :query_service, :persister, to: :metadata_adapter

  def initialize(logger = Logger.new(STDOUT))
    raise("DataSeeder is not for use in production!") if Rails.env == "production"
    @logger = logger
  end

  # This method should probably be phased out; new methods tested independently and called directly
  def generate_dev_data(many_files:, mvw_volumes:, sammel_files:, sammel_vols:)
    generate_resource_with_files(n: many_files)
    generate_multi_volume_work(n: mvw_volumes)
    generate_sammelband(file_count: sammel_files, volume_count: sammel_vols)
    generate_scanned_map
    generate_multi_volume_map_set(n: 2)
    generate_raster_resource
    generate_vector_resource
    generate_scanned_map_with_raster_child
    generate_map_set(n: 2)
    object_count_report
  end

  def generate_collection
    collection = Collection.new
    collection_change_set = CollectionChangeSet.new(collection)
    collection_change_set.validate(title: "The Important Person's Things", slug: "important-persons-things", owners: User.first.uid)
    output = change_set_persister.save(change_set: collection_change_set)
    resource = ScannedResource.new
    resource_change_set = ScannedResourceChangeSet.new(resource)
    resource_change_set.validate(title: "Historically Significant Resource", state: "pending", member_of_collection_ids: [output.id])
    change_set_persister.save(change_set: resource_change_set)
    resource = ScannedResource.new
    resource_change_set = ScannedResourceChangeSet.new(resource)
    resource_change_set.validate(title: "Culturally Significant Resource", state: "pending", member_of_collection_ids: [output.id])
    change_set_persister.save(change_set: resource_change_set)
    resource = ScannedResource.new
    resource_change_set = ScannedResourceChangeSet.new(resource)
    resource_change_set.validate(title: "Curious Resource", state: "complete", member_of_collection_ids: [output.id])
    change_set_persister.save(change_set: resource_change_set)
  end

  def generate_ephemera_project(project: EphemeraProject.new(title: "An Ephemera Project", slug: "test-project"), n_folders: 3, n_boxes: 1)
    load_vocabs
    project = persister.save(resource: project)
    logger.info "Created ephemera project #{project.id}: #{project.title}"
    add_ephemera_fields(project)
    n_boxes.times { add_ephemera_box(project) }
    box = query_service.find_by(id: project.id).decorate.boxes.first
    add_ephemera_folders(n: n_folders, project: project, box: box)
  end

  def generate_map_set(n:)
    parent = generate_scanned_map(title: "Map Set")
    n.times do
      add_child_resource(child: generate_scanned_map, parent_id: parent.id)
    end
  end

  def generate_multi_volume_work(n:)
    parent = generate_scanned_resource(title: "Multi volume work")
    n.times do
      add_child_resource(child: generate_resource_with_files(n: 1), parent_id: parent.id)
    end
  end

  def generate_resource_with_files(n:)
    sr = generate_scanned_resource(title: "Resource with #{n} files")
    sr = persister.save(resource: sr)
    n.times { add_file(resource: sr) }
    logger.info "Created scanned resource #{sr.id}: #{sr.title} with #{n} files"
    sr
  end

  def generate_sammelband(file_count:, volume_count:)
    parent = generate_scanned_resource(title: "Sammelband")
    file_count.times { add_file(resource: parent) }
    volume_count.times do
      add_child_resource(child: generate_resource_with_files(n: 1), parent_id: parent.id)
    end
  end

  def generate_scanned_map(attrs = {})
    sm = ScannedMap.new(attributes_hash.merge(geo_attributes).merge(attrs))
    sm = persister.save(resource: sm)
    add_file(resource: sm)
    logger.info "Created scanned map #{sm.id}: #{sm.title}"
    sm
  end

  def generate_scanned_map_with_no_file(attrs = {})
    sm = ScannedMap.new(attributes_hash.merge(geo_attributes).merge(attrs))
    sm = persister.save(resource: sm)
    logger.info "Created scanned map #{sm.id}: #{sm.title}"
    sm
  end

  def generate_multi_volume_map_set(n:)
    parent = generate_scanned_map_with_no_file(title: "Multi volume map set")
    volume1 = generate_scanned_map(title: "Volume 1")
    volume2 = generate_scanned_map(title: "Volume 2")
    add_child_resource(child: volume1, parent_id: parent.id)
    add_child_resource(child: volume2, parent_id: parent.id)

    n.times do
      add_child_resource(child: generate_scanned_map, parent_id: volume1.id)
      add_child_resource(child: generate_scanned_map, parent_id: volume2.id)
    end
  end

  def generate_scanned_map_with_raster_child
    parent = generate_scanned_map(title: "Scanned Map with Raster Child")
    add_file(resource: parent)
    add_child_resource(child: generate_raster_resource, parent_id: parent.id)
    logger.info "Created scanned map with raster child #{parent.id}: #{parent.title}"
    parent
  end

  def generate_scanned_resource(attrs = {})
    sr = ScannedResource.new(attributes_hash.merge(attrs))
    sr = persister.save(resource: sr)
    logger.info "Created scanned resource #{sr.id}: #{sr.title}"
    sr
  end

  def generate_raster_resource
    rr = RasterResource.new(attributes_hash.merge(geo_attributes))
    rr = persister.save(resource: rr)
    file = IngestableFile.new(file_path: Rails.root.join("spec", "fixtures", "files", "raster", "geotiff.tif"), mime_type: "image/tiff", original_filename: "geotiff.tif")
    add_file(resource: rr, file: file)
    logger.info "Created raster resource #{rr.id}: #{rr.title}"
    rr
  end

  def generate_vector_resource
    vr = VectorResource.new(attributes_hash.merge(geo_attributes))
    vr = persister.save(resource: vr)
    file = IngestableFile.new(file_path: Rails.root.join("spec", "fixtures", "files", "vector", "shapefile.zip"), mime_type: "application/zip", original_filename: "shapefile.zip")
    add_file(resource: vr, file: file)
    logger.info "Created vector resource #{vr.id}: #{vr.title}"
    vr
  end

  def generate_archival_recording
    recording = ScannedResource.new(title: "Archival Recording")
    recording_change_set = RecordingChangeSet.new(recording)
    recording = change_set_persister.save(change_set: recording_change_set)

    path = Rails.root.join("spec", "fixtures", "av", "la_c0652_2017_05_bag2")
    bag = ArchivalMediaBagParser.new(path: path, component_id: "C0652")
    audio_files = bag.send(:audio_files)

    file_set_title = audio_files.first.barcode_with_side_and_part
    file_set = FileSet.new(title: file_set_title, side: audio_files.first.side, part: audio_files.first.part, barcode: audio_files.first.barcode, read_groups: [])

    storage_adapter = Valkyrie::StorageAdapter.find(:disk_via_copy)

    audio_files.each do |ingestable_audio_file|
      file_metadata_node = FileMetadata.for(file: ingestable_audio_file).new(id: SecureRandom.uuid)
      file = storage_adapter.upload(file: ingestable_audio_file, resource: file_metadata_node, original_filename: ingestable_audio_file.original_filename)
      file_metadata_node.file_identifiers = file_metadata_node.file_identifiers + [file.id]
      file_set.file_metadata += [file_metadata_node]
    end

    file_set = change_set_persister.save(change_set: FileSetChangeSet.new(file_set))

    recording = query_service.find_by(id: recording.id)
    recording_change_set = RecordingChangeSet.new(recording)
    recording_change_set.member_ids += [file_set.id]
    change_set_persister.save(change_set: recording_change_set)
  end

  def wipe_files!
    [Figgy.config["derivative_path"], Figgy.config["repository_path"]].each do |dir_path|
      Pathname.new(dir_path).children.each(&:rmtree) if Pathname.new(dir_path).exist?
    end
  end

  def wipe_metadata!
    Valkyrie::MetadataAdapter.adapters.each_value { |adapter| adapter.persister.wipe! }
  end

  private

    def add_child_resource(child:, parent_id:)
      change_set = ChangeSet.for(child)
      change_set.append_id = parent_id
      change_set_persister.save(change_set: change_set)
    end

    def add_ephemera_box(project)
      change_set = ChangeSet.for(EphemeraBox.new)
      change_set.validate(barcode: "00000000000000", box_number: "1")
      box = change_set_persister.save(change_set: change_set)
      add_member(parent: project, member: box)
      box
    end

    def add_ephemera_fields(project)
      [
        ["1", "LAE Languages"],
        ["2", "LAE Areas"],
        ["3", "LAE Areas"],
        ["4", "LAE Genres"],
        ["5", "LAE Subjects"]
      ].each do |pair|
        # create the ephemera field
        field_change_set = ChangeSet.for(EphemeraField.new)
        vocab = query_service.custom_queries.find_ephemera_vocabulary_by_label(label: pair[1])
        raise "Could not ingest the field for #{pair[0]}!" unless field_change_set.validate(field_name: [pair[0]], member_of_vocabulary_id: vocab.id)
        updated_field = change_set_persister.save(change_set: field_change_set)
        # add the field to the project
        add_member(parent: project, member: updated_field)
      end
    end

    def add_ephemera_folders(n:, project:, box:)
      n.times do |i|
        change_set = ChangeSet.for(EphemeraFolder.new)
        change_set.validate(
          barcode: "00000000000000",
          folder_number: i,
          title: Faker::Food.dish,
          language: [query_service.custom_queries.find_ephemera_term_by_label(label: "English").id],
          genre: query_service.custom_queries.find_ephemera_term_by_label(label: "Brochures").id,
          subject: [query_service.custom_queries.find_ephemera_term_by_label(label: "Architecture").id],
          local_identifier: "xyz#{i}",
          width: rand(50),
          height: rand(100),
          page_count: rand(600),
          description: Faker::Matz.quote
        )
        folder = change_set_persister.save(change_set: change_set)
        add_file(resource: folder)
        add_member(parent: box || project, member: folder)
      end
    end

    def add_file(resource:, file: nil)
      ingestable_file = file || IngestableFile.new(file_path: Rails.root.join("spec", "fixtures", "files", "example.tif"), mime_type: "image/tiff", original_filename: "example.tif")
      change_set = ChangeSet.for(resource)
      change_set.files = [ingestable_file]
      change_set_persister.save(change_set: change_set)
    end

    def add_member(parent:, member:)
      member_change_set = ChangeSet.for(member)
      member_change_set.append_id = parent.id
      change_set_persister.save(change_set: member_change_set)
      logger.info "Added #{member.class} #{member.id} to #{parent.class} #{parent.title || parent.box_number}"
    end

    def attributes_hash
      {
        title: Faker::Space.star,
        description: Faker::Matz.quote,
        rights_statement: rights_statements[rand(rights_statements.count)].value,
        files: [],
        read_groups: "public",
        state: "complete",
        visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
        import_metadata: false,
        provenance: "the moon"
      }
    end

    def change_set_persister
      ::ChangeSetPersister.new(
        metadata_adapter: metadata_adapter,
        storage_adapter: Valkyrie.config.storage_adapter
      )
    end

    def coverage
      "northlimit=40.424427; eastlimit=-74.48246; southlimit=40.135958; westlimit=-74.939246; units=degrees; projection=EPSG:4326"
    end

    def geo_attributes
      {
        coverage: coverage,
        provenance: "Princeton",
        held_by: "Princeton"
      }
    end

    def load_vocabs
      to_load = [
        { file: "config/vocab/iso639-1.csv", name: "LAE Languages",
          columns: { label: "label", category: nil } },
        { file: "config/vocab/lae_areas.csv", name: "LAE Areas",
          columns: { label: "label", category: nil } },
        { file: File.join("spec", "fixtures", "lae_genres.csv"), name: "LAE Genres",
          columns: { label: "pul_label", category: nil } },
        { file: File.join("spec", "fixtures", "lae_subjects.csv"), name: "LAE Subjects",
          columns: { label: "subject", category: "category" } }
      ]
      to_load.each do |vocab|
        change_set_persister.buffer_into_index do |buffered_change_set_persister|
          IngestVocabService.new(buffered_change_set_persister, vocab[:file], vocab[:name], vocab[:columns], logger).ingest
        end
      end
    end

    def metadata_adapter
      Valkyrie::MetadataAdapter.find(:indexing_persister)
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

    def rights_statements
      ControlledVocabulary.for(:rights_statement).all
    end
end
