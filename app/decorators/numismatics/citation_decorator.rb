# frozen_string_literal: true
module Numismatics
  class CitationDecorator < Valkyrie::ResourceDecorator
    display :part,
            :number,
            :numismatic_reference,
            :uri

    delegate :decorated_numismatic_reference, to: :wayfinder

    def manageable_files?
      false
    end

    def manageable_structure?
      false
    end

    def part
      Array.wrap(super).first
    end

    def number
      Array.wrap(super).first
    end

    def numismatic_reference
      decorated_numismatic_reference.short_title
    end

    def title
      "#{decorated_numismatic_reference&.indexed_title} #{part} #{number}"
    end
  end
end
