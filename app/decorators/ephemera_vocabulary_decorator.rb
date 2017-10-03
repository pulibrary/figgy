# frozen_string_literal: true
class EphemeraVocabularyDecorator < Valkyrie::ResourceDecorator
  self.display_attributes = [:label, :uri, :definition, :categories, :terms]

  def to_s
    label
  end

  def title
    to_s
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

  def vocabulary_label
    vocabulary.blank? ? 'Unnassigned' : vocabulary.label
  end

  def find_references
    @referenced_by ||=
      begin
        query_service.find_inverse_references_by(resource: model, property: :member_of_vocabulary_id).to_a

      end
  end

  def categories
    @categories ||=
      find_references.select { |r| r.is_a?(EphemeraVocabulary) }
                     .map(&:decorate)
                     .sort_by(&:label)
  end

  def terms
    @terms ||=
      find_references.select { |r| r.is_a?(EphemeraTerm) }
                     .map(&:decorate)
                     .sort_by(&:label)
  end

  def manageable_files?
    false
  end

  def manageable_structure?
    false
  end
end
