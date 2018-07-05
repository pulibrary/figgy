# frozen_string_literal: true
module Types::Resource
  include Types::BaseInterface
  description "A resource in the system."
  orphan_types Types::ScannedResourceType, Types::FileSetType

  field :id, String, null: true
  field :label, String, null: true
  field :viewing_hint, String, null: true
  field :url, String, null: true
  field :members, [Types::Resource], null: true
  field :source_metadata_identifier, String, null: true
  field :thumbnail, Types::Thumbnail, null: true

  definition_methods do
    def resolve_type(object, _context)
      "Types::#{object.class}Type".constantize
    end
  end

  def members
    @members ||= Wayfinder.for(object).members
  end

  def url
    @url ||= helper.show_url(object)
  end

  def helper
    @helper ||= ManifestBuilder::ManifestHelper.new
  end

  def thumbnail
    return if object.try(:thumbnail_id).blank? || thumbnail_resource.blank?
    {
      id: thumbnail_resource.id.to_s,
      thumbnail_url: helper.manifest_image_thumbnail_path(thumbnail_resource.id.to_s),
      iiif_service_url: helper.manifest_image_path(thumbnail_resource)
    }
  end

  def thumbnail_resource
    @thumbnail_resource ||= query_service.find_by(id: object.try(:thumbnail_id).first)
  rescue Valkyrie::Persistence::ObjectNotFoundError
    nil
  end

  def query_service
    Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
  end
end
