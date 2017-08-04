# frozen_string_literal: true
class FileSet < Valhalla::Resource
  include Valkyrie::Resource::AccessControls
  attribute :id, Valkyrie::Types::ID.optional
  attribute :title, Valkyrie::Types::Set
  attribute :member_ids, Valkyrie::Types::Array

  def thumbnail_id
    derivative_file.try(:id)
  end

  def derivative_file
    @derivative_file ||= members.find(&:derivative?)
  end

  def original_file
    @derivative_file ||= members.find(&:original_file?)
  end

  private

    def members
      @members ||= Valkyrie.config.metadata_adapter.query_service.find_members(resource: self).to_a
    end
end
