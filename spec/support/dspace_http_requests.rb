# frozen_string_literal: true

module DspaceHttpRequests
  def stub_dspace_collection_requests(headers:, collection_id:, item_handle:)
    items_query = "https://dataspace.princeton.edu/rest/collections/#{collection_id}/items"
    items_query_response = [
      {
        "handle": item_handle
      }
    ].to_json

    stub_request(:get, items_query).with(
      headers: {
        "Accept": "application/json"
      },
      query: {
        "limit": 20,
        "offset": 0
      }
    ).to_return(
      status: 200,
      body: items_query_response
    )

    # Request the Collection Resource using the Handle
    collection_response_body = {
      "id": collection_id,
      "name": "Test DSpace Collection",
      "type": "collection"
    }.to_json

    stub_request(:get,
                   "https://dataspace.princeton.edu/rest/handle/#{handle}").to_return(
                    status: 200,
                    headers: headers,
                    body: collection_response_body
                  )

    # Request the Collection Resource using the ID
    stub_request(:get,
                   "https://dataspace.princeton.edu/rest/collections/#{collection_id}").to_return(
                    status: 200,
                    headers: headers,
                    body: collection_response_body
                  )
  end

  def stub_dspace_item_requests(headers:, item_id:, item_handle:)
    response_body = {
      "id": item_id,
      "type": "item"
    }.to_json

    stub_request(:get,
                  "https://dataspace.princeton.edu/rest/handle/#{item_handle}").to_return(
                  status: 200,
                  headers: headers,
                  body: response_body
                )
  end

  def stub_dspace_bitstream_requests(headers:, item_id:)
    bitstream_response = [
      {
        "name" => "test-name",
        "sequenceId" => "test-sequence-id"
      }
    ]

    stub_request(:get, "https://dataspace.princeton.edu/rest/items/#{item_id}/bitstreams?limit=20&offset=0").with(
      headers: {
        "Rest-Dspace-Token": 'secret'
      }
    ).to_return(
      status: 200,
      headers: headers,
      body: bitstream_response.to_json
    )
  end

  # This is to test for the public visibility of a DSpace Item
  def stub_dspace_visibility_request(headers:, item_id:)
    bitstream_response = [
      {
        "name" => "test-name",
        "sequenceId" => "test-sequence-id"
      }
    ]

    stub_request(:get,
                 "https://dataspace.princeton.edu/rest/items/#{item_id}/bitstreams?limit=1&offset=0").to_return(
                   status: 200,
                   headers: headers,
                   body: bitstream_response.to_json
                 )
  end

  def stub_dspace_access_restricted_request(headers:, item_id:)
    bitstream_response = []

    stub_request(:get, "https://dataspace.princeton.edu/rest/items/#{item_id}/bitstreams?limit=1&offset=0").to_return(
      status: 403,
      headers: headers,
      body: bitstream_response.to_json
    )
  end

  def stub_dspace_bitstream_forbidden_requests(headers:, item_id:)
    bitstream_response = []

    stub_request(:get,
                 "https://dataspace.princeton.edu/rest/items/#{item_id}/bitstreams?limit=20&offset=0").to_return(
                   status: 403,
                   headers: headers,
                   body: bitstream_response.to_json
                 )
  end

  def stub_dspace_catalog_requests(headers:, mms_id:, catalog_request_url:)
    # Request the catalog metadata for the Item
    catalog_response_meta = {
      "pages" => {
        "total_count" => 1
      }
    }
    catalog_response = {
      "meta" => catalog_response_meta,
      "data" => [
        {
          "id" => mms_id,
          "attributes" => {
            "electronic_portfolio_s" => nil
          }
        }
      ]
    }

    stub_request(:get, catalog_request_url).to_return(
                  status: 200,
                  headers: headers,
                  body: catalog_response.to_json
                )
  end

  def stub_dspace_catalog_missing_requests(headers:, catalog_request_url:)
    catalog_response_meta = {
      "pages" => {
        "total_count" => 0
      }
    }
    catalog_response = {
      "meta" => catalog_response_meta,
      "data" => []
    }

    stub_request(:get,
                  catalog_request_url).to_return(
                  status: 200,
                  headers: headers,
                  body: catalog_response.to_json
                )
  end

  def stub_dspace_invalid_catalog_requests(headers:, catalog_request_url:, mms_id:)
    catalog_response_meta = {
      "pages" => {
        "total_count" => 1
      }
    }
    catalog_response = {
      "meta" => catalog_response_meta,
      "data" => [
        {
          "id" => mms_id,
          "attributes" => {}
        }
      ]
    }

    stub_request(:get, catalog_request_url).to_return(
                  status: 200,
                  headers: headers,
                  body: catalog_response.to_json
                )
  end

  def stub_dspace_oai_requests(headers:, item_handle:, oai_fixture_path:)
    # Request the OAI metadata for the DSpace Item
    oai_document_fixture = File.read(oai_fixture_path)
    oai_document = Nokogiri::XML(oai_document_fixture)
    oai_response = oai_document.to_xml

    stub_request(:get,
                  "https://dataspace.princeton.edu/oai/request?identifier=oai:dataspace.princeton.edu:#{item_handle}&metadataPrefix=oai_dc&verb=GetRecord").to_return(
                  status: 200,
                  headers: headers,
                  body: oai_response
                )
  end
end

RSpec.configure do |config|
  config.include DspaceHttpRequests
end
