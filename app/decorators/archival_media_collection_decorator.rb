# frozen_string_literal: true
class ArchivalMediaCollectionDecorator < CollectionDecorator
  display Schema::Common.attributes
  suppress :source_jsonld, :source_metadata

  delegate(*Schema::Common.attributes, to: :primary_imported_metadata, prefix: :imported)

  # Display the resource attributes
  # @return [Hash] a Hash of all of the resource attributes
  def display_attributes
    super.reject { |k, v| imported_attributes.fetch(k, nil) == v }
  end

  def imported_attribute(attribute_key)
    return primary_imported_metadata.send(attribute_key) if primary_imported_metadata.try(attribute_key)
    Array.wrap(primary_imported_metadata.attributes.fetch(attribute_key, []))
  end

  # Access the resource attributes imported from an external service
  # @return [Hash] a Hash of all of the resource attributes
  def imported_attributes
    @imported_attributes ||= ImportedAttributes.new(subject: self, keys: self.class.displayed_attributes).to_h
  end

  def imported_created
    output = imported_attribute(:created)
    return if output.blank?
    # we know these will always be iso8601 so if there's a slash it's a range
    return output.map { |entry| display_date_range(entry) } if output.to_s.include? "/"
    output.map { |value| Date.parse(value.to_s).strftime("%B %-d, %Y") }
  end

  def imported_language
    imported_attribute(:language).map do |language|
      ControlledVocabulary.for(:language).find(language).label
    end
  end
  alias display_imported_language imported_language

  private

    def display_date_range(date_value)
      dates = date_value.to_s.split("/")
      dates.map! { |date| Date.parse(date).year }
      dates.join "-"
    end
end
