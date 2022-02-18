# frozen_string_literal: true

class PlaylistDecorator < Valkyrie::ResourceDecorator
  display :title,
    :visibility

  display_in_manifest [:title]

  delegate :file_sets, :members, to: :wayfinder

  def manageable_files?
    false
  end

  def orderable_files?
    true
  end

  def manageable_structure?
    true
  end

  def decorated_proxies
    members.map(&:decorate)
  end
end
