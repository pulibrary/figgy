# frozen_string_literal: true
module EzidStubbing
<<<<<<< HEAD
  def stub_ezid(shoulder:, blade:, location: "http://example.com")
    stub_request(:post, "https://ezid.cdlib.org/shoulder/ark:/#{shoulder}")
      .to_return(status: 200, body: "id: ark:/#{shoulder}#{blade}", headers: {})
    stub_request(:head, "http://arks.princeton.edu/ark:/#{shoulder}/#{blade}")
      .to_return(status: 301, headers: { location: "http://n2t.net/ark:/#{shoulder}/#{blade}" })
    stub_request(:head, "http://n2t.net/ark:/#{shoulder}/#{blade}")
      .to_return(status: 302, headers: { location: location })
=======
  def stub_ezid(shoulder:, blade:)
    stub_request(:post, "https://ezid.cdlib.org/shoulder/ark:/#{shoulder}")
      .to_return(status: 200, body: "id: ark:/#{shoulder}#{blade}", headers: {})
>>>>>>> d8616123... adds lux order manager to figgy
  end
end

RSpec.configure do |config|
  config.include EzidStubbing
end
Ezid::Client.configure do |conf| conf.logger = Logger.new(File::NULL); end
