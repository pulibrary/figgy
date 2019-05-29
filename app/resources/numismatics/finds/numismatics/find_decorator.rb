# frozen_string_literal: true
module Numismatics
  class FindDecorator < Valkyrie::ResourceDecorator
    display :place,
            :date,
            :find_number,
            :feature,
            :locus,
            :description

    def place
      Array.wrap(super).first
    end

    def date
      Array.wrap(super).first
    end

    def find_number
      Array.wrap(super).first
    end

    def feature
      Array.wrap(super).first
    end

    def locus
      Array.wrap(super).first
    end

    def description
      Array.wrap(super).first
    end
  end
end
