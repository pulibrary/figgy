# frozen_string_literal: true
module PulMetadataServices
  class Client
    class << self
      # Factory method for constructing BibRecord or PulfaRecord objects
      # @param id [String] the identifier
      # @return [PulMetadataServices::BibRecord, PulMetadataServices::AspacePulfaRecord]
      def retrieve(id)
        if catalog?(id)
          src = retrieve_from_catalog(id)
          PulMetadataServices::BibRecord.new(src)
        elsif (src = retrieve_from_aspace_pulfa(id))
          PulMetadataServices::AspacePulfaRecord.new(src)
        end
      end

      def retrieve_from_aspace_pulfa(id)
        conn = Faraday.new(url: Figgy.config[:findingaids_url])
        url = "#{id.tr('.', '-')}.json"
        url += "?auth_token=#{Figgy.pulfalight_unpublished_token}" if Figgy.pulfalight_unpublished_token.present?
        response = conn.get(url)
        return unless response.success?
        response.body.dup.force_encoding("UTF-8")
      end

      def retrieve_aspace_pulfa_ead(id)
        conn = Faraday.new(url: Figgy.config[:findingaids_url])
        response = conn.get("#{id.tr('.', '-')}.xml")
        return nil if response.status != 200
        response.body.dup.force_encoding("UTF-8")
      end

      # Determines whether or not a remote metadata identifier is an identifier for Voyager records
      # @param source_metadata_id [String] the remote metadata identifier
      # @return [Boolean]
      def catalog?(source_metadata_id)
        # 99*6421 will be in all alma IDs, and old Voyager records are
        # converted. We keep ID at 4 because the test suite has some low-number
        # IDs.
        # TODO: Increase length check after test suite is converted to Alma.
        return unless source_metadata_id.to_s.length > 4
        source_metadata_id =~ /\A\d+\z/
      end

      # Retrieves a MARC record (serialized in XML) from Voyager using an ID
      # @param id [String]
      # @return [String] string-serialized XML for the MARC record
      def retrieve_from_catalog(id)
        conn = Faraday.new(url: Figgy.config[:catalog_url])
        response = conn.get("#{id}.marcxml")
        response.body
      end
    end
  end
end
