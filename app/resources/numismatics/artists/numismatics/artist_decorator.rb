# frozen_string_literal: true
module Numismatics
  class ArtistDecorator < Valkyrie::ResourceDecorator
    display :person,
            :signature,
            :role,
            :side

    delegate :decorated_person, to: :wayfinder

    def manageable_files?
      false
    end

    def manageable_structure?
      false
    end

    def person
      return nil unless decorated_person
      [decorated_person.name1, decorated_person.name2].compact.join(" ")
    end

    def title
      [person, signature].compact.join(", ")
    end
  end
end
