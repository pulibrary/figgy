# frozen_string_literal: true

# Decorates geo resources for generation of geoblacklight document.
# Forwards geo attributes to an object containing merged direct and imported attribute values.
class GeoblacklightMetadataDecorator < SimpleDelegator
  extend Forwardable

  def_delegators :merged_attributes_object, *Schema::Geo.attributes

  private

    def merged_attributes_object
      @merged_attributes_object ||= OpenStruct.new(merged_attributes)
    end

    # Merge direct attribute values with imported attribute values and deduplicate.
    def merged_attributes
      direct_attributes.map do |key, value|
        imported_value = __getobj__.primary_imported_metadata.send(key) || []
        merged_values = no_merge_keys.include?(key) ? value : imported_value + value
        [key, merged_values.uniq]
      end.to_h
    end

    def direct_attributes
      Schema::Geo.attributes.index_with do |attribute|
        Array.wrap(__getobj__.[](attribute))
      end
    end

    # Keys that shouldn't be merged with imported metadata.
    def no_merge_keys
      [:identifier]
    end
end
