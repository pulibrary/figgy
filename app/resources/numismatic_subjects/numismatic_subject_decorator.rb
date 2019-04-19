# frozen_string_literal: true
class NumismaticSubjectDecorator < Valkyrie::ResourceDecorator
  display :type,
          :subject

  def manageable_files?
    false
  end

  def manageable_structure?
    false
  end

  def type
    Array.wrap(super).first
  end

  def subject
    Array.wrap(super).first
  end

  def title
    "#{type}, #{subject}"
  end
end
