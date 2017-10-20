# frozen_string_literal: true
class EphemeraTermDecorator < Valkyrie::ResourceDecorator
  display(
    [
      :label,
      :uri,
      :code,
      :tgm_label,
      :lcsh_label,
      :vocabulary
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

  def internal_url
    return Array.wrap(model.uri).first if vocabulary.blank?
    vocabulary_uri = vocabulary.uri.to_s.end_with?('/') ? vocabulary.uri.to_s : vocabulary.uri.to_s + '/'
    URI.join(vocabulary_uri, camelized_label)
  end

  def uri
    external_uri_exists? ? Array.wrap(super).first : internal_url
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

  private

    def metadata_adapter
      Valkyrie.config.metadata_adapter
    end

    def camelized_label
      Array.wrap(label).first.gsub(/\s/, '_').camelize(:lower)
    end
end
