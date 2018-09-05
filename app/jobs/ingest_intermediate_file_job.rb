# frozen_string_literal: true

# Class for jobs which ingest files as intermediate files and append them todo
#   an existing resource
class IngestIntermediateFileJob < ApplicationJob
  # Execute the job
  # @param [String] file_path the path to the file being ingested
  # @param [String] file_set_id the ID of the resource having the intermediate file appended
  # @param [Logger] logger
  def perform(file_path:, file_set_id:, logger: Valkyrie.logger)
    file_set = query_service.find_by(id: Valkyrie::ID.new(file_set_id))
    logger.info "Ingesting #{file_path} as an intermediate file..."

    @file_path = file_path

    change_set_persister.buffer_into_index do |buffered_persister|
      change_set = FileSetChangeSet.new(file_set)
      change_set.prepopulate!

      unless change_set.validate(files: [build_file])
        logger.error "#{self.class}: Failed to validate the file built for #{@file_path}: #{change_set.errors}"
        next
      end

      change_set.sync
      buffered_persister.save(change_set: change_set)

      logger.info "Ingested #{@file_path} as an intermediate file for #{file_set.id}"

      # Delete all existing derivatives
      derivative_file_ids = file_set.derivative_files.map do |derivative_file|
        derivative_file.file_identifiers.first
      end.compact

      CleanupFilesJob.set(queue: change_set_persister.queue).perform_now(file_identifiers: derivative_file_ids)
      CreateDerivativesJob.set(queue: change_set_persister.queue).perform_now(file_set.id.to_s)
    end
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
      [Valkyrie::Vocab::PCDMUse.IntermediateFile]
    end

    # Accesses the original filename for the file being ingested
    # @return [String]
    def original_filename
      File.basename(@file_path)
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
