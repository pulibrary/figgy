# frozen_string_literal: true
class EphemeraTermDecorator < Valkyrie::ResourceDecorator
  self.display_attributes = [:label, :uri, :code, :tgm_label, :lcsh_label, :vocabulary]

  def to_s
    label
  end

  def title
    label
  end

  def manageable_files?
    false
  end

  def manageable_structure?
    false
  end

  def vocabulary
    @vocabulary ||=
      begin
        query_service.find_references_by(resource: model, property: :member_of_vocabulary_id)
                     .select { |r| r.is_a?(EphemeraVocabulary) }
                     .map(&:decorate)
                     .to_a.first
      end
  end
end
