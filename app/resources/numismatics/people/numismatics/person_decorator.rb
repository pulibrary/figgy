# frozen_string_literal: true
module Numismatics
  class PersonDecorator < Valkyrie::ResourceDecorator
    display :name1,
            :name2,
            :epithet,
            :family,
            :born,
            :died,
            :class_of,
            :years_active_start,
            :years_active_end

    def manageable_files?
      false
    end

    def manageable_order?
      false
    end

    def manageable_structure?
      false
    end

    def title
      [name1, name2, epithet, date_range].compact.join(" ")
    end

    private

      def date_range
        return "(#{born&.first} to #{died&.first})" unless born.blank? && died.blank?
        return "(#{years_active_start&.first} to #{years_active_end&.first})" unless years_active_start.blank? && years_active_end.blank?
      end
  end
end
