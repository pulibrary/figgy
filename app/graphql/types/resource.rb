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

  # We need to centralize logic for navigating a MVW's members to find a
  # thumbnail file set. This is a hack to use the helper's logic for doing that.
<<<<<<< HEAD
  # refactor ticketed as https://github.com/pulibrary/figgy/issues/1708
=======
  # @TODO: Fix this.
>>>>>>> d8616123... adds lux order manager to figgy
  def helper
    @helper ||= ManifestBuilder::ManifestHelper.new.tap do |helper|
      helper.singleton_class.include(ThumbnailHelper)
      helper.define_singleton_method(:image_tag) do |url, _opts|
        url
      end
      helper.define_singleton_method(:image_path) do |url|
        url
      end
    end
  end

  def thumbnail
    return if object.try(:thumbnail_id).blank? || thumbnail_resource.blank?
    {
      id: thumbnail_resource.id.to_s,
      thumbnail_url: helper.figgy_thumbnail_path(thumbnail_resource),
      iiif_service_url: helper.figgy_thumbnail_path(thumbnail_resource).gsub("/full/!200,150/0/default.jpg", "")
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
