# frozen_string_literal: true
class EphemeraProjectChangeSet < Valkyrie::ChangeSet
  validates :title, :slug, presence: true
  property :title, multiple: false
  property :member_ids, multiple: true, required: false, type: Types::Strict::Array.member(Valkyrie::Types::ID)
  property :slug, multiple: false, required: true
  validate :slug_unique?
  validate :slug_valid?

  def primary_terms
    [:title, :slug]
  end

  def slug_valid?
    return if Slug.new(Array.wrap(slug).first).valid?
    errors.add(:slug, 'contains invalid characters, please only use alphanumerics, dashes, and underscores')
  end

  def slug_unique?
    return unless slug_exists?
    errors.add(:slug, 'is already in use by another project')
  end

  private

    def metadata_adapter
      Valkyrie.config.metadata_adapter
    end
    delegate :query_service, to: :metadata_adapter

    def slug_exists?
      slug_value = Array.wrap(slug).first
      results = query_service.custom_queries.find_by_string_property(property: :slug, value: slug_value).to_a
      !results.empty?
    end
end
