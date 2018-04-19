# frozen_string_literal: true
class EphemeraProjectChangeSet < Valkyrie::ChangeSet
  property :title, multiple: false
  property :member_ids, multiple: true, required: false, type: Types::Strict::Array.member(Valkyrie::Types::ID)
  property :slug, multiple: false, required: true
  property :top_language, multiple: true, required: false

  validates :title, :slug, presence: true
  validate :slug_unique?
  validate :slug_valid?

  validates_with MemberValidator

  def primary_terms
    [:title, :slug, :top_language]
  end

  def top_language=(top_language_values)
    return super(top_language_values) if top_language_values.blank?
    super(top_language_values.reject(&:blank?).map do |top_language_value|
      Valkyrie::ID.new(top_language_value)
    end)
  end

  def slug_valid?
    return if Slug.new(Array.wrap(slug).first).valid?
    errors.add(:slug, 'contains invalid characters, please only use alphanumerics, dashes, and underscores')
  end

  def slug_unique?
    return unless slug_exists?
    errors.add(:slug, 'is already in use by another project')
  end

  # @return array of EphemeraTerms available in an EphemeraField called 'language'
  def language_options
    model.decorate.fields.select { |field| field.attribute_name == 'language' }.map { |field| field.vocabulary.terms }.flatten
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
