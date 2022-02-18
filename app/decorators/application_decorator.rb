# frozen_string_literal: true

class ApplicationDecorator < Draper::Decorator
  class_attribute :displayed_attributes, :iiif_manifest_attributes
  self.displayed_attributes = []
  self.iiif_manifest_attributes = []
  delegate_all

  # Add a set of attributes to be displayed
  # @param attribute_names [Symbol] the symbolized names of the attributes being displayed
  def self.display(*attribute_names)
    self.displayed_attributes += Array.wrap(attribute_names.flatten)
  end

  # Remove a set of attributes from display
  # @param attribute_names [Symbol]
  def self.suppress(*attribute_names)
    self.displayed_attributes -= Array.wrap(attribute_names.flatten)
  end

  # Add an attribute to be displayed in the IIIF Manifest
  # @param attribute_name [Symbol] the symbolized name of the attribute being displayed

  def self.display_in_manifest(*attribute_names)
    self.iiif_manifest_attributes += Array.wrap(attribute_names.flatten)
  end

  # Remove a set of attributes from being displayed in the IIIF Manifest
  # @param attribute_names [Symbol]
  def self.suppress_from_manifest(*attribute_names)
    self.iiif_manifest_attributes -= Array.wrap(attribute_names.flatten)
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
      @keys.map do |attribute|
        [attribute, Array.wrap(@subject.[](attribute))]
      end.to_h
    end
  end

  class ImportedAttributes < Attributes
    def to_h
      return {} if map.empty?
      map.to_h
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
