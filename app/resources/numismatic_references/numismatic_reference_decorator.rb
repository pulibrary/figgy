# frozen_string_literal: true
class NumismaticReferenceDecorator < Valkyrie::ResourceDecorator
  display :author,
          :part_of_parent,
          :pub_info,
          :short_title,
          :title,
          :year

  delegate :members, :decorated_parent, to: :wayfinder

  def attachable_objects
    [NumismaticReference]
  end

  def manageable_files?
    false
  end

  def manageable_structure?
    false
  end
end
