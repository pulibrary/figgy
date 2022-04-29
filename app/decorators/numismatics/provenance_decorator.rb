# frozen_string_literal: true
module Numismatics
  class ProvenanceDecorator < Valkyrie::ResourceDecorator
    display :note,
            :date,
            :firm,
            :person

    delegate :decorated_firm, :decorated_person, to: :wayfinder

    def manageable_files?
      false
    end

    def manageable_structure?
      false
    end

    def firm
      return nil unless decorated_firm
      [decorated_firm.name, decorated_firm.city].compact.join(", ")
    end

    def person
      return nil unless decorated_person
      [decorated_person.name1, decorated_person.name2].compact.join(" ")
    end

    def title
      [firm, person, date, note].compact.join("; ")
    end
  end
end
