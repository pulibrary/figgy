# frozen_string_literal: true
module CatalogStubbing
  BIBDATA_SCHEME = "https"
  BIBDATA_HOST = "catalog.princeton.edu"
  BIBDATA_PATH = "/catalog"
  CONTENT_TYPE_JSON_LD = Mime::Type.lookup_by_extension("jsonld")
  CONTENT_TYPE_XML = Mime::Type.lookup_by_extension("xml")
  CONTENT_TYPE_MARC_XML = "application/marcxml+xml"

  def catalog_url(bib_id, content_type = CONTENT_TYPE_JSON_LD)
    path = [BIBDATA_PATH, bib_id].join("/")
    case content_type
    when CONTENT_TYPE_JSON_LD
      path = [path, "jsonld"].join(".")
    when CONTENT_TYPE_MARC_XML
      path = [path, "marcxml"].join(".")
    end

    uri = URI::Generic.build(scheme: BIBDATA_SCHEME, host: BIBDATA_HOST, path: path)
    uri.to_s
  end

  def catalog_fixture_path(bib_id, content_type = CONTENT_TYPE_JSON_LD)
    fixture_path = "files/catalog/#{bib_id}"

    case content_type
    when CONTENT_TYPE_JSON_LD
      fixture_path += ".jsonld"
    when CONTENT_TYPE_MARC_XML
      fixture_path += ".mrx"
    when CONTENT_TYPE_XML
      fixture_path += ".xml"
    end
    fixture_path
  end

  def stub_catalog(bib_id:, status: 200, content_type: CONTENT_TYPE_JSON_LD)
    url = catalog_url(bib_id, content_type)

    if status == 200
      fixture_path = catalog_fixture_path(bib_id, content_type)

      stub_request(:get, url)
        .to_return(
          body: file_fixture(fixture_path).read,
          headers: {
            "Content-Type" => content_type
          }
        )
    else
      stub_request(:get, url)
        .to_return(
          status: status
        )
      stub_request(:get, catalog_url("99#{bib_id}3506421", content_type))
        .to_return(
          status: status
        )
    end
  end

  def stub_findingaid(pulfa_id:, body: nil)
    json_url = "#{pulfalight_domain}/catalog/#{pulfa_id.tr('.', '-')}.json"
    json_url += "?auth_token=#{Figgy.pulfalight_unpublished_token}" if Figgy.pulfalight_unpublished_token
    stub_request(:get, json_url)
      .to_return(
        status: 200,
        headers: {
          "Content-Type" => "application/json"
        },
        body: body || file_fixture("files/pulfa/aspace/#{pulfa_id}.json").read
      )
    ead = Pathname.new(file_fixture_path).join("files/pulfa/aspace/#{pulfa_id}.ead.xml")
    return unless File.exist?(ead)
    stub_request(:get, "#{pulfalight_domain}/catalog/#{pulfa_id.tr('.', '-')}.xml")
      .to_return(
        status: 200,
        headers: {
          "Content-Type" => "application/xml"
        },
        body: File.read(ead)
      )
  end

  def stub_findingaid_error(pulfa_id:, status_code:)
    json_url = "#{pulfalight_domain}/catalog/#{pulfa_id.tr('/', '_')}.json"
    json_url += "?auth_token=#{Figgy.pulfalight_unpublished_token}" if Figgy.pulfalight_unpublished_token
    stub_request(:get, json_url)
      .to_return(
        status: status_code,
        headers: {
          "Content-Type" => "application/json"
        },
        body: { status: status_code, error: "Error" }.to_json
      )
  end

  def pulfalight_domain
    "https://findingaids.princeton.edu"
  end

  def stub_catalog_context
    stub_request(:get, "https://bibdata.princeton.edu/context.json")
      .to_return(
        body: file_fixture("files/catalog/context.json").read,
        headers: {
          "Content-Type" => "application/json"
        }
      )
  end
end

RSpec.configure do |config|
  config.include CatalogStubbing
end
