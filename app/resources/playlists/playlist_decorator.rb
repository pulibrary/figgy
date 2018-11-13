# frozen_string_literal: true
class PlaylistDecorator < Valkyrie::ResourceDecorator
  display :title,
          :visibility,
          :members

  display_in_manifest [:title]

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

  def proxies
    wayfinder.proxies.map(&:decorate)
  end

  def file_set_ids
    wayfinder.file_sets.map(&:id)
  end
end
