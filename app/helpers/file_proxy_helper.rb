# frozen_string_literal: true

module FileProxyHelper
  # @param [Playlist]
  # @return [Array[Hash]] Array of hash representations of file_proxies
  #   with "recording_url" and "recording_title" fields added
  def proxies_with_recording_data(playlist)
    proxy_data = JSON.parse(playlist.decorate.decorated_proxies.to_json)
    proxy_data.map do |proxy|
      file_set = Valkyrie.config.metadata_adapter.query_service.find_by(id: Valkyrie::ID.new(proxy["proxied_file_id"]["id"]))
      recording = Wayfinder.for(file_set).parent
      proxy.merge! "recording_url" => solr_document_url(recording), "recording_title" => recording.decorate.first_title.to_s
    end
  end
end
