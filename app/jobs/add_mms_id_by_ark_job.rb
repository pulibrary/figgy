# frozen_string_literal: true

class AddMmsIdByArkJob < ApplicationJob
  # queue_as :realtime
  queue_as :high

  def perform(resource_id:)
    @resource_id = resource_id

    catalog_url = Figgy.config[:catalog_url]
    catalog_uri = URI.parse(catalog_url)

    catalog_base_url = "#{catalog_uri.scheme}://#{catalog_uri.host}"
    headers = {
      "Accept": "application/json",
      "Content-Type": "application/json"
    }
    conn = Faraday.new(
      url: catalog_base_url,
      headers: headers
    )

    path = "catalog.json"
    ark_url = resource.identifier.first
    query = ark_url.gsub("http://arks.princeton.edu/ark:/", "")

    params = {
      "search_field": "electronic_access_1display",
      "q": query
    }

    response = conn.get(path, params)
    json_body = JSON.parse(response.body)

    results = json_body.fetch("data", [])
    raise(StandardError, "Failed to find the MMS ID: #{params}") if results.empty?

    valid_entries = results.select { |result| result.key?("id") }
    raise(StandardError, "Failed to find the key 'id' in the JSON #{valid_entries}") if valid_entries.empty?

    valid_eportfolio_entries = valid_entries.select { |result| result["attributes"].key?("electronic_access_1display") }
    raise(StandardError, "Failed to find the MMS ID with the `electronic_access_1display` attribute") if valid_eportfolio_entries.empty?

    matches = []
    matching_eportfolios = []
    valid_eportfolio_entries.each do |entry|
      eportfolios = entry["attributes"]["electronic_access_1display"]["attributes"]["value"]
      eportfolios.keys.each do |eportfolio|
        if eportfolio.include?(query)
          matching_eportfolios << eportfolio
          matches << entry["id"]
        end
      end
    end

    raise(StandardError, "Found more than one MMS ID for #{query}: #{matching_eportfolios}") if matches.length > 1
    result = matches.first

    @source_metadata_identifier = result

    change_set = ChangeSet.for(resource)
    change_set.validate(source_metadata_identifier: @source_metadata_identifier, apply_remote_metadata: "1")
    change_set_persister.save(change_set: change_set)
  end

  private

    def query_service
      Valkyrie.config.metadata_adapter.query_service
    end

    def resource
      @resource ||= query_service.find_by(id: @resource_id)
    end

    def change_set_persister
      ChangeSetPersister.default
    end
end
