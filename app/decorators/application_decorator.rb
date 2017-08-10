# frozen_string_literal: true
class ApplicationDecorator < Draper::Decorator
  class_attribute :suppressed_attributes, :display_attributes, :iiif_manifest_attributes
  self.suppressed_attributes = []
  self.display_attributes = []
  self.iiif_manifest_attributes = []
  delegate_all

  def self.imported_attributes(attribute_names)
    attribute_names.map { |attrib| ('imported_' + attrib.to_s).to_sym }
  end

  def display_attributes
    attributes(self.class.display_attributes - self.class.suppressed_attributes)
  end

  def iiif_manifest_attributes
    attributes(self.class.iiif_manifest_attributes)
  end

  def [](attribute)
    __send__(attribute)
  end

  delegate :model_name, :attributes, to: :object

  private

    def attributes(attribute_names)
      Hash[
        attribute_names.map do |attribute|
          [attribute, Array.wrap(self.[](attribute))]
        end
      ]
    end
end
