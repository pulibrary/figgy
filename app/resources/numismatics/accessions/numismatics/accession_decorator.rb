# frozen_string_literal: true
module Numismatics
  class AccessionDecorator < Valkyrie::ResourceDecorator
    display :accession_number,
            :date,
            :items_number,
            :type,
            :cost,
            :account,
            :person,
            :firm,
            :note,
            :private_note,
            :citations

    delegate :decorated_firm, :decorated_person, to: :wayfinder

    def account
      Array.wrap(super).first
    end

    def cost
      Array.wrap(super).first
    end

    def cost_label
      "(#{cost})" if cost
    end

    def citations
      numismatic_citation.map { |c| c.decorate.title }
    end

    def date
      Array.wrap(super).first
    end

    def firm
      decorated_firm&.name
    end

    def from_label
      divider = "/" if person && firm
      "#{person}#{divider}#{firm}"
    end

    def label
      "#{accession_number}: #{date} #{type} #{from_label} #{cost_label}"
    end

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

    def indexed_label
      "#{accession_number}: #{formatted_date} #{from_label}"
    end

    def formatted_date
      return unless date.present?
      Time.zone.parse(date.to_s)&.strftime("%F")
    end

    def title
      ["Accession #{accession_number}: #{date} #{type} #{from_label} #{cost_label}"]
    end

    def type
      Array.wrap(super).first
    end
  end
end
