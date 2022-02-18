# frozen_string_literal: true

module LinkedData
  class LinkedVocabularyBase < LinkedResource
    delegate(
      :external_uri_exists?,
      :label,
      :vocabulary,
      to: :decorated_resource
    )

    def uri
      Array.wrap(decorated_resource.uri).first
    end

    def internal_url
      decorated_resource.internal_url.to_s
    end

    def exact_match
      return {} unless external_uri_exists?
      {"exact_match" => {"@id" => uri}}
    end

    def linked_properties
      super.except(:title, :system_created_at, :system_updated_at)
    end
  end
end
