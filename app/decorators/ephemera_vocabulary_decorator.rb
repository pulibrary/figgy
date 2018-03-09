# frozen_string_literal: true
class EphemeraVocabularyDecorator < Valkyrie::ResourceDecorator
  display(
    [
      :label,
      :uri,
      :definition,
      :categories,
      :terms
    ]
  )

  def label
    Array.wrap(super).first
  end
  alias title label
  alias to_s label

  def external_uri_exists?
    value = Array.wrap(model.uri).first
    value.present?
  end

  def vocabulary_uri
    vocabulary.uri.to_s.end_with?('/') ? vocabulary.uri.to_s : vocabulary.uri.to_s + '/'
  end

  def vocabulary_ns
    Figgy.config['vocabulary_namespace'].end_with?('/') ? Figgy.config['vocabulary_namespace'] : Figgy.config['vocabulary_namespace'] + '/'
  end

  def internal_url
    if vocabulary.present? && vocabulary.uri.present?
      URI.join(vocabulary_uri, camelized_label)
    else
      URI.join(vocabulary_ns, camelized_label)
    end
  end

  def uri
    external_uri_exists? ? Array.wrap(super).first : internal_url
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
  rescue ArgumentError
    @referenced_by ||= []
  end

  # a category is just a nested vocabulary
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

  private

    def metadata_adapter
      Valkyrie.config.metadata_adapter
    end

    def camelized_label
      Array.wrap(label).first.gsub(/\s/, '_').camelize(:lower)
    end
end
