# frozen_string_literal: true
class SolrStatus < HealthMonitor::Providers::Base
  def check!
    uri = Blacklight.default_index.connection.uri
    status_uri = URI(uri.to_s.gsub(uri.path, "/solr/admin/cores?action=STATUS"))
    response = Net::HTTP.get(status_uri)
    json = JSON.parse(response)
    raise "The solr has an invalid status #{status_uri}" if json["responseHeader"]["status"] != 0
  end
end
