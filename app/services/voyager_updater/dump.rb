# frozen_string_literal: true

module VoyagerUpdater
  class Dump
    attr_reader :url

    # Constructor
    # @param url [String]
    def initialize(url)
      @url = url
    end

    # Retrieve the bib. IDs from the Voyager data dump marked as updated
    # @return [Array<String>]
    def update_ids
      parsed_json["ids"]["update_ids"]
    end

    # Retrieve the resource IDs for those resources marked for update
    # @return [Array<String>]
    def ids_needing_updated
      @ids_needing_updated ||=
        relevant_ids&.each_slice(100)&.flat_map do |ids|
          ids.map { |bib_id| resource(bib_id) }.compact.map { |resource| resource.id.to_s }
        end
    end

    private

      # Retrieve the bib. IDs used for the resource updates
      # @return [Array<String>]
      def relevant_ids
        update_ids
      end

      # Retrieve the JSON from Voyager and parse the values into a Hash
      # @return [Hash]
      def parsed_json
        @parsed_json ||= JSON.parse(open(url).read)
      end

      # Retrieves a resource using a Voyager bib. ID
      # @param bib_id [String]
      # @return [Resource, nil]
      def resource(bib_id)
        results = query_service.custom_queries.find_by_property(property: "source_metadata_identifier", value: bib_id).to_a
        return if results.empty?
        results.first
      end

      # Retrieves the query service from the metadata adapter
      # @return [Valkyrie::Persistence::Postgres::QueryService]
      def query_service
        Valkyrie.config.metadata_adapter.query_service
      end
  end
end
