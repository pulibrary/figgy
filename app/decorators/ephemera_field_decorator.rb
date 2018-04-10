# frozen_string_literal: true
# Decorator for EphemeraField Objects
class EphemeraFieldDecorator < Valkyrie::ResourceDecorator
  display :rendered_name, :vocabulary

  # Retrieves the EphemeraProjects to which this EphemeraField is linked
  # @return [Array<EphemeraProject>]
  def parents
    @parents ||= query_service.find_parents(resource: model).to_a
  end

  def projects
    @projects ||= parents.select { |r| r.is_a?(EphemeraProject) }.map(&:decorate).to_a
  end

  # Retrieves the label for the field name
  # @return [String]
  def name_label
    name_term.blank? ? 'Unnamed' : name_term.label
  end

  # Aliases the title to the field name
  # @return [String]
  def title
    name_label
  end

  # Retrieves the attribute name to which the EphemeraField is linked in its name
  # e. g. EphemeraFolder.language is linked to dc:language, EphemeraFolder.subject to dc:subject
  def attribute_name
    name_label.split('.').last
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

  # Retrieves the vocabulary from which the EphemeraField populates its terms
  # @return [EphemeraVocabulary] the vocabulary linked to the EphemeraField
  def vocabulary
    @vocabulary ||=
      begin
        query_service.find_references_by(resource: model, property: :member_of_vocabulary_id)
                     .map(&:decorate)
                     .to_a.first
      end
  end

  # Retrieves the label for the linked vocabulary
  # @return [String] the vocabulary label
  def vocabulary_label
    vocabulary.blank? ? 'Unnassigned' : vocabulary.label
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
end
