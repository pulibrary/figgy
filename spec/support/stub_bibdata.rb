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
end

RSpec.configure do |config|
  config.include BibdataStubbing
end
