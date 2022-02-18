# frozen_string_literal: true

# Decorator for EphemeraField Objects
class EphemeraFieldDecorator < Valkyrie::ResourceDecorator
  display :rendered_name, :vocabulary

  delegate :parents, to: :wayfinder

  # TODO: Rename to decorated_ephemera_projects
  def projects
    wayfinder.decorated_ephemera_projects
  end

  # Retrieves the vocabulary from which the EphemeraField populates its terms
  # @return [EphemeraVocabulary] the vocabulary linked to the EphemeraField
  # TODO: Rename to decorated_ephemera_vocabulary
  def vocabulary
    wayfinder.decorated_ephemera_vocabulary
  end

  def favorite_terms
    wayfinder.decorated_favorite_terms
  end

  def rarely_used_terms
    wayfinder.decorated_rarely_used_terms
  end

  # Returns categories or terms with rarely used terms at the end and favorite
  # terms at the beginning.
  def sorted_terms_or_categories
    return sorted_categories if attribute_name == "subject"
    non_favorite_terms = vocabulary.terms.select { |x| !favorite_term_ids.include?(x.id) && !rarely_used_term_ids.include?(x.id) }
    favorite_terms + non_favorite_terms + rarely_used_terms
  end

  # Retrieves the label for the field name
  # @return [String]
  def name_label
    name_term.blank? ? "Unnamed" : name_term.label
  end

  # Aliases the title to the field name
  # @return [String]
  def title
    name_label
  end

  # Retrieves the attribute name to which the EphemeraField is linked in its name
  # e. g. EphemeraFolder.language is linked to dc:language, EphemeraFolder.subject to dc:subject
  def attribute_name
    name_label.split(".").last
  end

  # Retrieves the HTML for a link to the EphemeraField
  # ControlledVocabulary::EphemeraField is used to resolve an authoritative label for the field name
  # @return [String] the HTML for the field name
  def rendered_name
    field_name.map do |name|
      term = ControlledVocabulary.for(:ephemera_field).find(name)
      next unless term
      h.link_to(term.label, term.value) +
        h.content_tag("br") +
        h.content_tag("p") do
          term.definition.html_safe
        end
    end
  end

  # Retrieves the label for the linked vocabulary
  # @return [String] the vocabulary label
  def vocabulary_label
    vocabulary.blank? ? "Unnassigned" : vocabulary.label
  end

  # Ensures that users cannot manage files for this Resource
  # @return [Boolean]
  def manageable_files?
    false
  end

  # Ensures that users cannot manage a IIIF structure for this Resource
  # @return [Boolean]
  def manageable_structure?
    false
  end

  private

    # Retrieve the ControlledVocabulary::EphemeraField name for this resource
    # @return [ControlledVocabulary::EphemeraField::Term]
    def name_term
      @name_term ||= ControlledVocabulary.for(:ephemera_field).find(field_name.first)
    end

    # Returns categories where favorite terms appear at the top and rarely used
    # terms are removed from categories and placed at the bottom. Favorite terms
    # appear in both their respective category and in "favorites"
    def sorted_categories
      [favorite_category] + categories_without_rare_terms + [rarely_used_category]
    end

    def categories_without_rare_terms
      vocabulary.categories.map do |category|
        terms = category.terms.select do |term|
          !rarely_used_term_ids.include?(term.id)
        end
        OpenStruct.new(
          label: category.label,
          terms: terms
        )
      end
    end

    def favorite_category
      OpenStruct.new(
        label: "Favorites",
        terms: favorite_terms
      )
    end

    def rarely_used_category
      OpenStruct.new(
        label: "Rarely Used",
        terms: rarely_used_terms
      )
    end
end
