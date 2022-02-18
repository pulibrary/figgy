# frozen_string_literal: true

class EphemeraProjectChangeSet < Valkyrie::ChangeSet
  property :title, multiple: false
  property :member_ids, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID)
  property :slug, multiple: false, required: true
  property :top_language, multiple: true, required: false
  property :contributor_uids, multiple: true, required: false

  validates :title, :slug, presence: true

  validates_with MemberValidator
  validates_with UniqueSlugValidator

  def primary_terms
    [:title, :slug, :contributor_uids, :top_language]
  end

  def top_language=(top_language_values)
    return super(top_language_values) if top_language_values.blank?
    super(top_language_values.reject(&:blank?).map do |top_language_value|
      Valkyrie::ID.new(top_language_value)
    end)
  end

  # @return array of EphemeraTerms available in an EphemeraField called 'language'
  def language_options
    model.decorate.fields.select { |field| field.attribute_name == "language" }.map { |field| field.vocabulary.terms }.flatten
  end

  # There's no real state to manage here. Just always preserve.
  def preserve?
    true
  end

  # Don't automatically preserve children on save. Children have their own
  # states and will preserve on complete.
  def preserve_children?
    false
  end
end
