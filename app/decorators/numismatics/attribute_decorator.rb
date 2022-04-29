# frozen_string_literal: true
module Numismatics
  class AttributeDecorator < Valkyrie::ResourceDecorator
    display :description,
            :name

    def manageable_files?
      false
    end

    def manageable_structure?
      false
    end

    def description
      Array.wrap(super).first
    end

    def name
      Array.wrap(super).first
    end

    def title
      [name, description].compact.join(", ")
    end
  end
end
