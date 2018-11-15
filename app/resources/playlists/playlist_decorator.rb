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

  def decorated_proxies
    members.map(&:decorate)
  end
end
