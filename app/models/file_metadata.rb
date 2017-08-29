# frozen_string_literal: true
class FileMetadata < Valkyrie::Resource
  include Valkyrie::Resource::AccessControls
  attribute :id, Valkyrie::Types::ID.optional
  attribute :label, Valkyrie::Types::Set
  attribute :mime_type, Valkyrie::Types::Set
  attribute :height, Valkyrie::Types::Set
  attribute :width, Valkyrie::Types::Set
  attribute :checksum, Valkyrie::Types::Set
  attribute :original_filename, Valkyrie::Types::Set
  attribute :file_identifiers, Valkyrie::Types::Set
  attribute :use, Valkyrie::Types::Set
  attribute :size, Valkyrie::Types::Set

  def self.for(file:)
    new(label: file.original_filename, original_filename: file.original_filename, mime_type: file.content_type, use: file.try(:use) || [Valkyrie::Vocab::PCDMUse.OriginalFile])
  end

  def original_file?
    use.include?(Valkyrie::Vocab::PCDMUse.OriginalFile)
  end

  def derivative?
    use.include?(Valkyrie::Vocab::PCDMUse.ServiceFile)
  end
end
