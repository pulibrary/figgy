# frozen_string_literal: true
class PlaylistDecorator < Valkyrie::ResourceDecorator
  display :title,
          :visibility,
          :members,
          :authorized_link

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

  # Provide the authorization token to build the authorized link at the Controller layer
  # @return [String]
  def authorized_link
    auth_token
  end
end
