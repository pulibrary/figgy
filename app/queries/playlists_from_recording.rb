# frozen_string_literal: true

class PlaylistsFromRecording
  def self.queries
    [:playlists_from_recording]
  end

  attr_reader :query_service
  delegate :run_query, to: :query_service
  def initialize(query_service:)
    @query_service = query_service
  end

  def playlists_from_recording(recording:)
    run_query(query(recording: recording), id: recording.id.to_s)
  end

  def query(recording:)
    <<-SQL
      select * from orm_resources a WHERE
      public.get_ids(a.metadata, 'member_ids') ?| (
        select array_agg((a.id)::text) from orm_resources a,
        orm_resources b
        WHERE a.internal_resource = 'ProxyFileSet'
        AND b.id = :id
        AND public.get_ids_array(a.metadata, 'proxied_file_id') && (public.get_ids_array(b.metadata, 'member_ids'))
      )
    SQL
  end
end
