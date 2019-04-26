# frozen_string_literal: true
class NumismaticReferenceDecorator < Valkyrie::ResourceDecorator
  display :authors,
          :part_of_parent,
          :pub_info,
          :short_title,
          :title,
          :year

  delegate :decorated_parent, :decorated_authors, :members, to: :wayfinder

  def attachable_objects
    [NumismaticReference]
  end

  def authors
    decorated_authors.map(&:title)
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
