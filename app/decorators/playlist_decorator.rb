# frozen_string_literal: true
class PlaylistDecorator < Valkyrie::ResourceDecorator
  display :label,
          :visibility

  display_in_manifest [:label]

  delegate :members, to: :wayfinder

  def manageable_files?
    false
  end

  def orderable_files?
    true
  end

  def manageable_structure?
    false
  end

  def titles
    Array.wrap(label)
  end
  alias title titles
end
