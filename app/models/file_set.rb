# frozen_string_literal: true
class FileSet < Valhalla::Resource
  include Valkyrie::Resource::AccessControls
  attribute :id, Valkyrie::Types::ID.optional
  attribute :title, Valkyrie::Types::Set
  attribute :file_metadata, Valkyrie::Types::Set.member(FileMetadata.optional)
  attribute :viewing_hint
  attribute :depositor
  attribute :local_identifier

  delegate :width, :height, :mime_type, :size, to: :original_file, allow_nil: true
  delegate :md5, :sha1, :sha256, to: :original_file_checksum, allow_nil: true

  def thumbnail_id
    id
  end

  def derivative_file
    file_metadata.find(&:derivative?)
  end

  def original_file
    file_metadata.find(&:original_file?)
  end

  private

    def original_file_checksum
      original_file&.checksum&.first
    end
end
