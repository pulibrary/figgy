# frozen_string_literal: true
class RiiifResolver < Riiif::AbstractFileSystemResolver
  attr_writer :input_types
  delegate :query_service, to: :metadata_adapter

  def pattern(id)
    raise ArgumentError, "Invalid characters in id `#{id}`" unless /^[\w\-:]+$/.match?(id)
    file_set = query_service.find_by(id: Valkyrie::ID.new(id))
    file_metadata = file_set.derivative_files.find { |x| x.mime_type == ["image/tiff"] } || file_set.derivative_file
    raise Valkyrie::Persistence::ObjectNotFoundError, id if file_metadata.nil?
    derivative_file = Valkyrie::StorageAdapter.find_by(id: file_metadata.file_identifiers.first)
    derivative_file.io.path
  end

  private

    def metadata_adapter
      Valkyrie.config.metadata_adapter
    end
end
