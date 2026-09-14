class EventGenerator
  class GeoblacklightEventGenerator
    attr_reader :bulk

    # @param bulk [Boolean] controls if solr is commited after each update
    def initialize(bulk: false)
      @bulk = bulk
    end

    def derivatives_created(record); end

    def derivatives_deleted(record); end

    def record_created(record); end

    def record_deleted(record)
      PulmapDeleteJob.set(queue: sidekiq_queue).perform_later(slug: slug(record), commit: commit?)
    end

    def record_updated(record)
      state = record.state.first
      if state == "takedown"
        record_deleted(record)
      elsif state == "complete"
        PulmapIndexJob.set(queue: sidekiq_queue).perform_later(document: document(record), commit: commit?)
      end
    end

    def record_member_updated(record)
      record_updated(record)
    end

    def valid?(record)
      return false if record.is_a?(FileSet)
      return false unless record.try(:geo_resource?)
      return false if schema_errors?(record)

      true
    end

    private

      def sidekiq_queue
        if bulk
          :super_low
        else
          :high
        end
      end

      def commit?
        !bulk
      end

      def document(record)
        document_generator(record).to_json
      end

      def document_generator(record)
        GeoDiscovery::DocumentBuilder.new(record, GeoDiscovery::GeoblacklightDocument.new)
      end

      def slug(record)
        GeoDiscovery::DocumentBuilder::SlugBuilder.new(record).slug
      end

      def schema_errors?(record)
        begin
          doc = document_generator(record).to_hash
          return true unless doc[:error].nil?
        rescue
          # the resource could not generate a document at all
          return false
        end

        false
      end
  end
end
