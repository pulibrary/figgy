# frozen_string_literal: true
class IngestMultivolumeAssetJob < ApplicationJob
  def perform(directory:, property: nil, change_set_param: nil, class_name: "ScannedResource", file_filters: [], **options)
    Rails.logger.info "Ingesting folder #{directory}"
    change_set_persister = ChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie::StorageAdapter.find(:disk_via_copy)
    )
    change_set_persister.queue = queue_name

    persisted_resources = []
    change_set_persister.buffer_into_index do |buffered_change_set_persister|
      ingest_service = BulkIngestService.new(change_set_persister: buffered_change_set_persister, change_set_param: change_set_param, klass: class_name.constantize, logger: Rails.logger)
      file_filters = typed_file_filter(class_name) if file_filters.empty?
      persisted_resource = ingest_service.attach_dir(base_directory: directory, property: property, file_filters: file_filters, **options)
      persisted_resources << persisted_resource
    end

    attributes = options.dup
    attributes[:member_ids] = persisted_resources.map(&:id)
    resource = new_resource(klass: class_name.constantize, **attributes)
    change_set = ChangeSet.for(resource, change_set_param: change_set_param)
    change_set.validate(member_ids: child_resources.map(&:id), files: child_files)
    change_set_persister.save(change_set: change_set)

    Rails.logger.info "Imported #{directory}"
  end

  private

    # Determines the file extension filter based upon the name of the class for the resource
    # @param class_name [String] the name of the class used to determine the file filter
    # @return [String]
    def typed_file_filter(class_name)
      case class_name
      when "ScannedResource"
        [".tif", ".wav", ".pdf", ".zip", ".jpg", ".mp4"]
      else
        Rails.logger.warn "Ingesting a folder with an unsupported class: #{class_name}"
        []
      end
    end

    # Create a new repository resource
    # @param klass [Class] the class of the resource being constructed
    # @return [Resource] the newly created resource
    def new_resource(klass:, **attributes)
      resource = klass.new

      change_set = ChangeSet.for(resource, change_set_param: change_set_param)
      raise("Invalid #{change_set}: #{change_set.errors}") unless change_set.validate(**attributes)

      persisted = change_set_persister.save(change_set: change_set)
      logger.info "Created the resource #{persisted.id}"
      persisted
    end


end
