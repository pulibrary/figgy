# frozen_string_literal: true
class EphemeraVocabularyDecorator < Valkyrie::ResourceDecorator
  display :label, :uri, :definition, :categories, :terms

  # TODO: Rename to decorated_vocabulary
  def vocabulary
    wayfinder.decorated_parent_vocabulary
  end

  # a category is just a nested vocabulary
  # TODO: Rename to decorated_vocabularies
  def categories
    @categories ||= wayfinder.decorated_vocabularies.sort_by(&:label)
  end

  # TODO: Rename to decorated_ephemera_terms
  def terms
    @terms ||= wayfinder.decorated_ephemera_terms.sort_by(&:label)
  end

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
    vocabulary.uri.to_s.end_with?("/") ? vocabulary.uri.to_s : vocabulary.uri.to_s + "/"
  end

  def vocabulary_ns
    Figgy.config["vocabulary_namespace"].end_with?("/") ? Figgy.config["vocabulary_namespace"] : Figgy.config["vocabulary_namespace"] + "/"
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

  def vocabulary_label
    vocabulary.blank? ? "Unnassigned" : vocabulary.label
  end

  def manageable_files?
    false
  end

  def manageable_structure?
    false
  end

  def breadcrumb_hierarchy
    [wayfinder.decorated_parent_vocabulary].compact
  end

  private

    def camelized_label
      Array.wrap(label).first.gsub(/\s/, "_").camelize(:lower)
    end
end
