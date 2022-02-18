# frozen_string_literal: true

module PulMetadataServices
  class Client
    class << self
      # Factory method for constructing BibRecord or PulfaRecord objects
      # @param id [String] the identifier
      # @param model [Resource] the model being described by the remote record
      # @return [PulMetadataServices::BibRecord, PulMetadataServices::PulfaRecord]
      def retrieve(id, model = nil)
        if bibdata?(id)
          src = retrieve_from_bibdata(id)
          record = PulMetadataServices::BibRecord.new(src)
        elsif (src = retrieve_from_aspace_pulfa(id))
          record = PulMetadataServices::AspacePulfaRecord.new(src)
        else
          src = retrieve_from_pulfa(id)
          full_src = full_source_from_pulfa(id)
          record = PulMetadataServices::PulfaRecord.new(src, model, full_src)
        end
        record
      end

      def retrieve_from_aspace_pulfa(id)
        conn = Faraday.new(url: Figgy.config[:findingaids_aspace_url])
        response = conn.get("#{id.tr(".", "-")}.json")
        return nil if response.status != 200
        response.body.dup.force_encoding("UTF-8")
      end

      def retrieve_aspace_pulfa_ead(id)
        conn = Faraday.new(url: Figgy.config[:findingaids_aspace_url])
        response = conn.get("#{id.tr(".", "-")}.xml")
        return nil if response.status != 200
        response.body.dup.force_encoding("UTF-8")
      end

      # Determines whether or not a remote metadata identifier is an identifier for Voyager records
      # @param source_metadata_id [String] the remote metadata identifier
      # @return [Boolean]
      def bibdata?(source_metadata_id)
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
      def retrieve_from_bibdata(id)
        conn = Faraday.new(url: Figgy.config[:bibdata_url])
        response = conn.get(id)
        response.body
      end

      private

        # Retrieves information about archival records in the Princeton University Library Finding Aids (PULFA) service using an ID
        # @param id [String]
        # @return [String] string-serialized XML for record information Document
        def retrieve_from_pulfa(id)
          conn = Faraday.new(url: Figgy.config[:legacy_findingaids_url])
          response = conn.get("#{id.tr("_", "/")}.xml", scope: "record")
          response.body.dup.force_encoding("UTF-8")
        end

        # Retrieves an EAD Document (XML) from the Princeton University Library Finding Aids (PULFA) service using an ID
        # @param id [String]
        # @return [String] string-serialized XML for the EAD Document
        def full_source_from_pulfa(id)
          conn = Faraday.new(url: Figgy.config[:legacy_findingaids_url])
          response = conn.get("#{id.tr("_", "/")}.xml")
          response.body.dup.force_encoding("UTF-8")
        end
    end
  end
end
