# frozen_string_literal: true
module BibdataStubbing
  BIBDATA_SCHEME = "https"
  BIBDATA_HOST = "bibdata.princeton.edu"
  BIBDATA_PATH = "/bibliographic"
  CONTENT_TYPE_JSON_LD = Mime::Type.lookup_by_extension("jsonld")
  CONTENT_TYPE_XML = Mime::Type.lookup_by_extension("xml")
  CONTENT_TYPE_MARC_XML = "application/marcxml+xml"

  def bibdata_url(bib_id, content_type = CONTENT_TYPE_JSON_LD)
    path = [BIBDATA_PATH, bib_id].join("/")
    case content_type
    when CONTENT_TYPE_JSON_LD
      path = [path, "jsonld"].join("/")
    end

    uri = URI::Generic.build(scheme: BIBDATA_SCHEME, host: BIBDATA_HOST, path: path)
    uri.to_s
  end

  def bibdata_fixture_path(bib_id, content_type = CONTENT_TYPE_JSON_LD)
    fixture_path = "bibdata/#{bib_id}"

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

  def stub_bibdata(bib_id:, status: 200, content_type: CONTENT_TYPE_JSON_LD)
    url = bibdata_url(bib_id, content_type)

    if status == 200
      fixture_path = bibdata_fixture_path(bib_id, content_type)

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
      stub_request(:get, bibdata_url("99#{bib_id}3506421", content_type))
        .to_return(
          status: status
        )
    end
  end

  def stub_pulfa(pulfa_id:, body: nil)
    pulfa_id = pulfa_id.tr("_", "/")
    stub_request(:get, "https://findingaids.princeton.edu/collections/#{pulfa_id}.xml?scope=record")
      .to_return(
        body: body || file_fixture("pulfa/#{pulfa_id}.xml").read,
        headers: {
          "Content-Type" => "application/json+ld"
        }
      )
    stub_request(:get, "https://findingaids.princeton.edu/collections/#{pulfa_id}.xml")
      .to_return(
        body: body || file_fixture("pulfa/#{pulfa_id}_full.xml").read,
        headers: {
          "Content-Type" => "application/json+ld"
        }
      )
    # If we're stubbing pulfa, it's not in aspace, so return 404 from there.
    stub_request(:get, "#{aspace_domain}/catalog/#{pulfa_id.tr('/', '_')}.json")
      .to_return(
        status: 404,
        headers: {
          "Content-Type" => "application/json"
        },
        body: { status: 404, error: "Not Found" }.to_json
      )
  end

  def stub_aspace(pulfa_id:, body: nil)
    stub_request(:get, "#{aspace_domain}/catalog/#{pulfa_id.tr('.', '-')}.json")
      .to_return(
        status: 200,
        headers: {
          "Content-Type" => "application/json"
        },
        body: body || file_fixture("pulfa/aspace/#{pulfa_id}.json").read
      )
    ead = Pathname.new(file_fixture_path).join("pulfa/aspace/#{pulfa_id}.ead.xml")
    return unless File.exist?(ead)
    stub_request(:get, "#{aspace_domain}/catalog/#{pulfa_id.tr('.', '-')}.xml")
      .to_return(
        status: 200,
        headers: {
          "Content-Type" => "application/xml"
        },
        body: File.read(ead)
      )
  end

  def aspace_domain
    "https://findingaids-beta.princeton.edu"
  end

  def stub_bibdata_context
    stub_request(:get, "https://bibdata.princeton.edu/context.json")
      .to_return(
        body: file_fixture("bibdata/context.json").read,
        headers: {
          "Content-Type" => "application/json"
        }
      )
  end
end

RSpec.configure do |config|
  config.include BibdataStubbing
end
