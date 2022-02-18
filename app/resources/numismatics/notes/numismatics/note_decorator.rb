# frozen_string_literal: true

module Numismatics
  class NoteDecorator < Valkyrie::ResourceDecorator
    display :note,
      :type

    def manageable_files?
      false
    end

    def manageable_structure?
      false
    end

    def note
      Array.wrap(super).first
    end

    def title
      note
    end
  end
end
