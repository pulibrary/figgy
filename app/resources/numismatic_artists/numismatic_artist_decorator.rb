# frozen_string_literal: true
class NumismaticArtistDecorator < Valkyrie::ResourceDecorator
  display :person,
          :signature,
          :role,
          :side

  def manageable_files?
    false
  end

  def manageable_structure?
    false
  end

  def person
    Array.wrap(super).first
  end

  def role
    Array.wrap(super).first
  end

  def title
    "#{person}, #{role}"
  end
end
