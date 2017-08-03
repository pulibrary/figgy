# frozen_string_literal: true
class FileSet < Valhalla::Resource
  include Valkyrie::Resource::AccessControls
  attribute :id, Valkyrie::Types::ID.optional
  attribute :title, Valkyrie::Types::Set
  attribute :member_ids, Valkyrie::Types::Array

  def thumbnail_id
    @thumbnail_id ||= Valkyrie.config.metadata_adapter.query_service.find_members(resource: self).find { |x| x.use.include?(Valkyrie::Vocab::PCDMUse.ServiceFile) }.try(:id)
  end
end
