# frozen_string_literal: true

# Class for jobs which ingest files as intermediate files and append them todo
#   an existing resource
class IngestIntermediateFileJob < ApplicationJob
  # Execute the job
  # @param [String] file_path the path to the file being ingested
  # @param [String, Valkyrie::ID] id the ID for the resource having the intermediate file appended
  # @param [Symbol] property the metadata property used to query for the existing resource
  # @param [String] value the metadata value used to query for the existing resource
  # @raise [Valkyrie::Persistence::ObjectNotFoundError]
  def perform(file_path:, id: nil, property: nil, value: nil)
    Valkyrie.logger.info "Ingesting #{file_path} as an intermediate file..."

    @file_path = file_path
    change_set_persister.buffer_into_index do |buffered_persister|
      if !id.nil?
        resource = metadata_adapter.query_service.find_by(id: id)
      elsif !property.nil? && !value.nil?
        results = metadata_adapter.query_service.custom_queries.find_by_string_property(property: property, value: value)
        resources = results.to_a
        break if resources.empty?
        resource = resources.first
      end

      file_sets = resource.decorate.file_sets
      file_sets.each do |file_set|
        change_set = FileSetChangeSet.new(file_set)
        change_set.prepopulate!

        break unless change_set.validate(files: [build_file])
        change_set.sync
        buffered_persister.save(change_set: change_set)

        Valkyrie.logger.info "Ingested #{file_path} as an intermediate file for #{resource.id}"
      end
    end
  rescue Valkyrie::Persistence::ObjectNotFoundError => not_found_error
    Valkyrie.logger.error "#{self.class}: Resource not found using ID: #{id}, property: #{property}, and value: #{value}"
    raise not_found_error
  end

  private

    # Class for wrapping the file being ingested and appended
    class IoDecorator < SimpleDelegator
      attr_reader :original_filename, :content_type, :use

      # @param [IO] io stream for the file content
      # @param [String] original_filename
      # @param [String] content_type
      # @param [RDF::URI] use the URI for the PCDM predicate indicating the use for this resource
      def initialize(io, original_filename, content_type, use)
        @original_filename = original_filename
        @content_type = content_type
        @use = use
        super(io)
      end
    end

    # Retrieves the metadata adapter for persisting and indexing resources
    # @return [IndexingAdapter]
    def metadata_adapter
      Valkyrie::MetadataAdapter.find(:indexing_persister)
    end

    # Retrieves the storage adapter for copying files to disk
    # @return [InstrumentedStorageAdapter]
    def storage_adapter
      Valkyrie::StorageAdapter.find(:disk_via_copy)
    end

    # Retrieves the query service using the metadata adapter
    # @return [InstrumentedAdapter::InstrumentedQueryService]
    delegate :query_service, to: :metadata_adapter

    # Constructs a new change set persister for ingesting the resources
    # @return [ChangeSetPersister]
    def change_set_persister
      @change_set_persister ||= ChangeSetPersister.new(
        metadata_adapter: metadata_adapter,
        storage_adapter: storage_adapter
      )
    end

    # Constructs the file stream for reading the content from the file being
    #   being ingested and appended
    # @return [File]
    def file_stream
      @file_stream ||= File.open(@file_path, "rb")
    end

    # Generate the use URIs for the intermediate resource
    # @return [Array<RDF::URI>]
    def use
      [Valkyrie::Vocab::PCDMUse.ServiceFile]
    end

    # Accesses the original filename for the file being ingested
    # @return [String]
    def original_filename
      @file_path.basename.to_s
    end

    # Determine the content type for the file being ingested
    # @return [MIME::Type]
    def file_content_type
      types = MIME::Types.type_for(original_filename)
      types.first
    end

    # Constructs the IoDecorator for ingesting the intermediate file
    # @return [IoDecorator]
    def build_file
      IoDecorator.new(file_stream, original_filename, file_content_type.to_s, use)
    end
end
