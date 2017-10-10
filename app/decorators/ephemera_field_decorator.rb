# frozen_string_literal: true
class EphemeraFieldDecorator < Valkyrie::ResourceDecorator
  self.display_attributes = [:rendered_name, :vocabulary]

  def projects
    @projects ||= parents.select { |r| r.is_a?(EphemeraProject) }.map(&:decorate).to_a
  end

  def name_label
    name_term.blank? ? 'Unnamed' : name_term.label
  end

  def title
    name_label
  end

  def attribute_name
    name_label.split('.').last
  end

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

  def vocabulary
    @vocabulary ||=
      begin
        query_service.find_references_by(resource: model, property: :member_of_vocabulary_id)
                     .map(&:decorate)
                     .to_a.first
      end
  end

  def vocabulary_label
    vocabulary.blank? ? 'Unnassigned' : vocabulary.label
  end

  def manageable_files?
    false
  end

  def manageable_structure?
    false
  end

  private

    def name_term
      @name_term ||= ControlledVocabulary.for(:ephemera_field).find(field_name.first)
    end
end
