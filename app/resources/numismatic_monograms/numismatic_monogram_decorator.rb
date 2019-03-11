# frozen_string_literal: true
class NumismaticMonogramDecorator < Valkyrie::ResourceDecorator
  display :title

  delegate :decorated_file_sets, to: :wayfinder

  def manageable_files?
    true
  end

  def manageable_structure?
    false
  end

  def title
    Array.wrap(super).first
  end

  def manageable_order?
    false
  end
end
