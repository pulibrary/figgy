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
        conn = Faraday.new(url: "https://findingaids-beta.princeton.edu/catalog/")
        response = conn.get("#{id}.json")
        return nil if response.status != 200
        response.body.dup.force_encoding("UTF-8")
      end

      # Determines whether or not a remote metadata identifier is an identifier for Voyager records
      # @param source_metadata_id [String] the remote metadata identifier
      # @return [Boolean]
      def bibdata?(source_metadata_id)
        source_metadata_id =~ /\A\d+\z/
      end

      # Retrieves a MARC record (serialized in XML) from Voyager using an ID
      # @param id [String]
      # @return [String] string-serialized XML for the MARC record
      def retrieve_from_bibdata(id)
        conn = Faraday.new(url: "https://bibdata.princeton.edu/bibliographic/")
        response = conn.get(id)
        response.body
      end

      private

        # Retrieves information about archival records in the Princeton University Library Finding Aids (PULFA) service using an ID
        # @param id [String]
        # @return [String] string-serialized XML for record information Document
        def retrieve_from_pulfa(id)
          conn = Faraday.new(url: "https://findingaids.princeton.edu/collections/")
          response = conn.get("#{id.tr('_', '/')}.xml", scope: "record")
          response.body.dup.force_encoding("UTF-8")
        end

        # Retrieves an EAD Document (XML) from the Princeton University Library Finding Aids (PULFA) service using an ID
        # @param id [String]
        # @return [String] string-serialized XML for the EAD Document
        def full_source_from_pulfa(id)
          conn = Faraday.new(url: "https://findingaids.princeton.edu/collections/")
          response = conn.get("#{id.tr('_', '/')}.xml")
          response.body.dup.force_encoding("UTF-8")
        end
    end
  end
end
