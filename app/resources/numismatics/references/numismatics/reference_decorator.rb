# frozen_string_literal: true

module Numismatics
  class ReferenceDecorator < Valkyrie::ResourceDecorator
    display :authors,
      :part_of_parent,
      :pub_info,
      :short_title,
      :title,
      :year

    delegate :decorated_parent, :decorated_authors, :members, to: :wayfinder

    def attachable_objects
      [Numismatics::Reference]
    end

    def authors
      decorated_authors.map { |a| [a.name1, a.name2].compact.join(" ") }
    end

    def indexed_title
      [short_title, authors.first, title, year].compact.join(", ")
    end

    def manageable_files?
      false
    end

    def manageable_structure?
      false
    end

    def short_title
      Array.wrap(super).first
    end

    def title
      Array.wrap(super).first
    end
  end
end
