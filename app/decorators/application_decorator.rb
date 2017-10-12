# frozen_string_literal: true
class ApplicationDecorator < Draper::Decorator
  class_attribute :displayed_attributes, :iiif_manifest_attributes
  self.displayed_attributes = []
  self.iiif_manifest_attributes = []
  delegate_all

  # Add a set of attributes to be displayed
  # @param attribute_names [Symbol] the symbolized names of the attributes being displayed
  def self.display(attribute_names)
    attribute_names = Array.wrap(attribute_names)
    self.displayed_attributes += attribute_names
  end

  # Remove a set of attributes from display
  # @param attribute_names [Symbol]
  def self.suppress(attribute_names)
    attribute_names = Array.wrap(attribute_names)
    attribute_names.each { |attribute_name| self.displayed_attributes.delete(attribute_name) }
  end

  # Add an attribute to be displayed in the IIIF Manifest
  # @param attribute_name [Symbol] the symbolized name of the attribute being displayed
  def self.iiif_manifest_display(attribute_names)
    attribute_names = Array.wrap(attribute_names)
    self.iiif_manifest_attributes += attribute_names
  end

  def self.iiif_manifest_suppress(attribute_names)
    attribute_names = Array.wrap(attribute_names)
    attribute_names.each { |attribute_name| self.iiif_manifest_attributes.delete(attribute_name) }
  end

  delegate :model_name, :attributes, to: :object

  # Accessor method for resource attributes
  # @param attribute [Symbol] the symbolized name of the attribute
  # @return [Object, nil] value of the attribute in the resource
  def [](attribute)
    __send__(attribute)
  end

  # Display the resource attributes
  # @return [Hash] a Hash of all of the resource attributes
  def display_attributes
    @display_attributes ||= Attributes.new(subject: self, keys: self.class.displayed_attributes).to_h
  end

  # Display the resource attributes for the IIIF Manifest
  # @return [Hash] a Hash of all of the resource attributes
  def iiif_manifest_attributes
    @iiif_manifest_attributes ||= Attributes.new(subject: self, keys: self.class.iiif_manifest_attributes).to_h
  end

  class Attributes
    def initialize(subject:, keys:)
      @subject = subject
      @keys = keys
    end

    def to_h
      Hash[
        @keys.map do |attribute|
          [attribute, Array.wrap(@subject.[](attribute))]
        end
      ]
    end
  end

  class ImportedAttributes < Attributes
    def to_h
      return {} if map.empty?
      Hash[map]
    end

    private

      def imported_key(attribute)
        "imported_#{attribute}".to_sym
      end

      def attribute_imported?(attribute)
        @subject.respond_to?(imported_key(attribute)) && @subject.[](imported_key(attribute)).present?
      end

      def values
        @keys.map do |attribute|
          next unless attribute.present? && attribute_imported?(attribute)
          [attribute, Array.wrap(@subject.[](imported_key(attribute)))]
        end
      end

      def map
        @map ||= values.reject { |_k, v| v.nil? }
      end
  end
end
