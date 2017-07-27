# frozen_string_literal: true
module BibdataStubbing
  def stub_bibdata(bib_id:, status: 200)
    if status == 200
      stub_request(:get, "https://bibdata.princeton.edu/bibliographic/#{bib_id}/jsonld")
        .to_return(
          body: file_fixture("bibdata/#{bib_id}.jsonld").read,
          headers: {
            'Content-Type' => "application/json+ld"
          }
        )
    else
      stub_request(:get, "https://bibdata.princeton.edu/bibliographic/#{bib_id}/jsonld")
        .to_return(
          status: status
        )
    end
  end

  def stub_pulfa(pulfa_id:, body: nil)
    pulfa_id = pulfa_id.gsub("_", "/")
    stub_request(:get, "https://findingaids.princeton.edu/collections/#{pulfa_id}.xml?scope=record")
      .to_return(
        body: body || file_fixture("pulfa/#{pulfa_id}.xml").read,
        headers: {
          'Content-Type' => "application/json+ld"
        }
      )
  end
end

RSpec.configure do |config|
  config.include BibdataStubbing
end
