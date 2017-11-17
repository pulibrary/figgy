# frozen_string_literal: true
class IngestableFile < Valkyrie::Resource
  attribute :id, Valkyrie::Types::String
  attribute :file_path, Valkyrie::Types::String
  attribute :mime_type, Valkyrie::Types::String
  attribute :original_filename, Valkyrie::Types::String
  # Hash of attributes to apply to the FileSet created when ingesting this file.
  attribute :container_attributes, Valkyrie::Types::Hash
  # Hash of attributes to apply to the FileMetadata node when ingesting this
  # file.
  attribute :node_attributes, Valkyrie::Types::Hash
  attribute :use
  # Whether or not the file is being copied by the storage adapter - will create
  # a duplicate of file_path on disk to use otherwise.
  attribute :copyable, Valkyrie::Types::Bool

  def content_type
    mime_type
  end

  def path
    return file_path if copyable
    copied_file_name
  end

  private

    def copied_file_name
      return @copied_file_name if @copied_file_name
      basename = Pathname.new(file.path).basename
      @copied_file_name = Tempfile.new([basename.to_s.split(".").first, basename.extname]).tap do |f|
        FileUtils.cp(File.open(file.path).path, f.path)
      end.path
    end

    def file
      @file ||= File.open(file_path)
    end
end
