class SolrStatus < HealthMonitor::Providers::Base
  def check!
    uri = Blacklight.default_index.connection.uri
    ping_uri = "#{uri}admin/ping"
    req = Net::HTTP::Get.new(ping_uri)
    req.basic_auth(uri.user, uri.password) if uri.user && uri.password
    response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }
    json = JSON.parse(response.body)
    raise "The solr has an invalid status #{ping_uri}" if json["responseHeader"]["status"] != 0
  end
end
