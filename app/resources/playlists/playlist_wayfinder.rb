# frozen_string_literal: true

class PlaylistWayfinder < BaseWayfinder
  # All valid relationships for a Playlist
  relationship_by_property :members, property: :member_ids

  # Resolves the proxied relationships with FileSets
  # @return [Array<FileSet>]
  def file_sets
    return @file_sets unless @file_sets.nil?

    valid_proxies = members.reject { |proxy| proxy.proxied_file_id.nil? }
    proxy_ids = valid_proxies.map(&:proxied_file_id)
    @file_sets ||=
      begin
        file_sets = query_service.find_many_by_ids(ids: proxy_ids)
        file_sets.each do |file_set|
          file_set.loaded[:proxy_parent] = members.find { |member| member.proxied_file_id == file_set.id }
        end
        # Find_many_by_ids doesn't guaruntee order. This sorts the returned file
        # sets by the members they were queried from.
        file_sets.sort_by { |x| proxy_ids.index(x.id) }
      end
  end

  def members_with_parents
    @members_with_parents ||= query_service.find_members(resource: resource).map do |member|
      member.loaded[:parents] = [resource]
      member
    end
  end
end
