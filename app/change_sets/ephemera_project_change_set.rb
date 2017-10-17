# frozen_string_literal: true
class EphemeraProjectChangeSet < Valkyrie::ChangeSet
  validates :title, :slug, presence: true
  property :title, multiple: false
  property :member_ids, multiple: true, required: false, type: Types::Strict::Array.member(Valkyrie::Types::ID)
  property :slug, multiple: false, required: true

  def primary_terms
    [:title, :slug]
  end

  def validate(resource_params = nil)
    # Ensure that the property is unique
    slug = resource_params.fetch(:slug, nil)
    if slug
      slug_value = Array.wrap(slug).first
      results = query_service.custom_queries.find_by_string_property(property: :slug, value: slug_value).to_a
      return false unless results.empty?
    end
    super(resource_params)
  end

  private

    def metadata_adapter
      Valkyrie.config.metadata_adapter
    end
    delegate :query_service, to: :metadata_adapter
end
