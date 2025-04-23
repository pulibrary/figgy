# frozen_string_literal: true

class AddMmsIdByArkJob < ApplicationJob
  # queue_as :realtime
  queue_as :high

  class FindMmsIdByArkError < StandardError; end

  def error_klass
    FindMmsIdByArkError
  end

  def perform(resource_id:)
    @resource_id = resource_id

    change_set = ChangeSet.for(resource)
    change_set.validate(source_metadata_identifier: source_metadata_identifier, apply_remote_metadata: "1")
    change_set_persister.save(change_set: change_set)
  rescue FindMmsIdByArkError => error
    Rails.logger.error(error.message)
    Honeybadger.notify(error)
    AddMmsIdByTitleJob.perform_later(resource_id: resource_id)
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

    def connection
      catalog_url = Figgy.config[:catalog_url]
      catalog_uri = URI.parse(catalog_url)

      catalog_base_url = "#{catalog_uri.scheme}://#{catalog_uri.host}"
      headers = {
        "Accept": "application/json",
        "Content-Type": "application/json"
      }

      Faraday.new(
        url: catalog_base_url,
        headers: headers
      )
    end

    def query
      ark_url = resource.identifier.first
      ark_url.gsub("http://arks.princeton.edu/ark:/", "")
    end

    def search_field
      "electronic_access_1display"
    end

    def results
      @results ||= begin
                     path = "catalog.json"
                     params = {
                       "search_field": search_field,
                       "q": query
                     }

                     response = connection.get(path, params)
                     json_body = JSON.parse(response.body)

                     fetched = json_body.fetch("data", [])
                     raise(error_klass, "Failed to find the MMS ID: #{params}") if fetched.empty?
                     fetched
                   end
    end

    def attribute_key
      "electronic_access_1display"
    end

    def attribute_value
      query
    end

    def valid_documents
      @valid_documents ||= results.select { |result| result.key?("attributes") && result["attributes"].key?(attribute_key) }
      raise(error_klass, "Failed to find the MMS ID with the `#{attribute_key}` attribute") if @valid_documents.empty?

      @valid_documents
    end

    def find_catalog_records
      matches = []
      valid_documents.each do |document|
        pairs = document["attributes"][attribute_key]
        next unless pairs.key?("attributes")
        attributes = pairs["attributes"]
        next unless attributes.key?("value")

        entries = attributes["value"]
        entries = entries.keys if entries.is_a?(Hash)
        entries.each do |entry|
          if entry.include?(attribute_value)
            matches << document["id"]
          end
        end
      end

      matches
    end

    def find_catalog_record
      matches = find_catalog_records
      raise(error_klass, "Found more than one MMS ID for #{query}: #{matches}") if matches.length > 1

      matches.first
    end

    def source_metadata_identifier
      @source_metadata_identifier ||= find_catalog_record
    end
end
