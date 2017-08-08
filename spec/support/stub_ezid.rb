# frozen_string_literal: true
module EzidStubbing
  def stub_ezid(shoulder:, blade:)
    stub_request(:post, "https://ezid.cdlib.org/shoulder/ark:/#{shoulder}")
      .to_return(status: 200, body: "id: ark:/#{shoulder}#{blade}", headers: {})
  end
end

RSpec.configure do |config|
  config.include EzidStubbing
end
Ezid::Client.configure do |conf| conf.logger = Logger.new(File::NULL); end
