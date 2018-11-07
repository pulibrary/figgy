# frozen_string_literal: true
class PlaylistWayfinder < BaseWayfinder
  # All valid relationships for a Playlist
  relationship_by_property :proxies, property: :member_ids

  # Resolves the proxied relationships with FileSets
  # @return [Array<FileSet>]
  def file_sets
    valid_proxies = proxies.reject { |proxy| proxy.proxied_file_id.nil? }
    query_service.find_many_by_ids(ids: valid_proxies.map(&:proxied_file_id))
  end
  alias members file_sets
end
