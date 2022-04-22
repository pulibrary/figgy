# frozen_string_literal: true
module Types::Resource
  include Types::BaseInterface
  description "A resource in the system."
  orphan_types Types::Numismatics::CoinType,
               Types::EphemeraFolderType,
               Types::FileSetType,
               Types::Numismatics::IssueType,
               Types::Numismatics::MonogramType,
               Types::PlaylistType,
               Types::ProxyFileSetType,
               Types::ScannedMapType,
               Types::ScannedResourceType,
               Types::RasterResourceType,
               Types::VectorResourceType

  field :id, String, null: true
  field :label, String, null: true
  field :viewing_hint, String, null: true
  field :url, String, null: true
  field :members, [Types::Resource], null: true
  field :orangelight_id, String, null: true
  field :source_metadata_identifier, String, null: true
  field :thumbnail, Types::Thumbnail, null: true
  field :ocr_content, [String], null: true
  field :embed, Types::EmbedType, null: true

  definition_methods do
    def resolve_type(object, _context)
      "Types::#{object.class}Type".constantize
    end
  end

  def members
    # This loads members but pre-populates the object as the members' parent
    # relationship in `loaded` so that each member won't have to query for its
    # parent. The FileSet decorator takes advantage of this in
    # `FileSetDecorator#parent`.
    @members ||= Wayfinder.for(object).members_with_parents
  end

  def manifest_url
    helper.polymorphic_url([:manifest, object])
  end

  def orangelight_id
    Array.wrap(object.try(:source_metadata_identifier)).first
  end

  def url
    @url ||= helper.show_url(object)
  end

  def ocr_content
    @ocr_content ||= Wayfinder.for(object).file_sets.select do |file_set|
      file_set.ocr_content.present?
    end.flat_map(&:ocr_content)
  end

  # We need to centralize logic for navigating a MVW's members to find a
  # thumbnail file set. This is a hack to use the helper's logic for doing that.
  # refactor ticketed as https://github.com/pulibrary/figgy/issues/1708
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
    return unless ability&.can?(:manifest, object)
    return if object.try(:thumbnail_id).blank? || thumbnail_resource.blank?

    figgy_thumbnail_path = helper.figgy_thumbnail_path(thumbnail_resource)
    return if figgy_thumbnail_path.nil?

    # Explicitly set this nil if the service URL cannot be parsed
    iiif_service_url = nil
    service_substr = "/full/!200,150/0/default.jpg"
    if figgy_thumbnail_path.include?(service_substr)
      iiif_service_url = figgy_thumbnail_path.gsub(service_substr, "")
    end
    {
      id: thumbnail_resource.id.to_s,
      thumbnail_url: figgy_thumbnail_path,
      iiif_service_url: iiif_service_url
    }
  end

  def thumbnail_resource
    @thumbnail_resource ||=
      begin
        members.find do |member|
          member.id == object.try(:thumbnail_id).first
        end || query_service.find_by(id: object.try(:thumbnail_id).first)
      end
  rescue Valkyrie::Persistence::ObjectNotFoundError
    nil
  end

  def embed; end

  def query_service
    Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
  end

  def ability
    context[:ability]
  end
end
