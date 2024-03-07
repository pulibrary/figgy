# frozen_string_literal: true
class SolrStatus < HealthMonitor::Providers::Base
  def check!
    uri = Blacklight.default_index.connection.uri
    status_uri = URI(uri.to_s.gsub(uri.path, "/solr/admin/cores?action=STATUS"))
    req = Net::HTTP::Get.new(status_uri)
    req.basic_auth(uri.user, uri.password) if uri.user && uri.password
    response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }
    json = JSON.parse(response.body)
    raise "The solr has an invalid status #{status_uri}" if json["responseHeader"]["status"] != 0
  end
end
