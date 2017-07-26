# frozen_string_literal: true
class ApplicationDecorator < Draper::Decorator
  class_attribute :display_attributes
  self.display_attributes = []
  delegate_all

  def display_attributes
    Hash[
      self.class.display_attributes.map do |attribute|
        [attribute, Array.wrap(self.[](attribute))]
      end
    ]
  end

  def [](attribute)
    __send__(attribute)
  end

  delegate :model_name, to: :object
end
