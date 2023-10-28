# frozen_string_literal: true
module CloudFixity
  require "google/cloud/pubsub"
  class Worker
    def self.pubsub_topic
      @pubsub_topic ||= Figgy.config["fixity_status_topic"]
    end

    def self.pubsub_subscription
      @pubsub_subscription ||= Figgy.config["fixity_status_topic"]
    end

    def self.run!
      Rails.logger.info "Running worker to check for fixity updating"

      new.run!
    end

    def run!
      topic = pubsub.topic(self.class.pubsub_topic)
      subscription = topic.subscription(self.class.pubsub_subscription)

      subscriber = subscription.listen do |message|
        message.acknowledge!
        data = JSON.parse(message.data.to_s, symbolize_names: true)
        CloudFixityJob.perform_later(status: data[:status], preservation_object_id: data[:resource_id], child_property: data[:child_property], child_id: data[:child_id])
      end

      # Start background threads that will call block passed to listen.
      subscriber.start

      # Fade into a deep sleep as worker will run indefinitely
      sleep
    rescue SignalException
      Rails.logger.info "Shutting down pubsub workers..."
    end

    def pubsub
      @pubsub ||= Google::Cloud::Pubsub.new
    end
  end

  class FixityRequestor
    def self.pubsub
      @pubsub ||= Google::Cloud::Pubsub.new
    end

    def self.pubsub_topic
      @pubsub_topic ||= Figgy.config["fixity_request_topic"]
    end

    def self.queue_daily_check!(annual_percent:)
      divisor = 365.0 * annual_percent
      preservation_count = query_service.custom_queries.count_all_of_model(model: PreservationObject)
      limit = (preservation_count / divisor).ceil
      resources = query_service.custom_queries.find_random_resources_by_model(limit: limit, model: PreservationObject)
      topic = pubsub.topic(pubsub_topic)
      resources.each_slice(100).each do |resource_slice|
        topic.publish do |publisher|
          queue_resources(resource_slice, publisher)
        end
      end
      Rails.logger.info "Enqueued #{limit} PreservationObjects for Cloud Fixity Checking"
    end

    def self.queue_resource_check!(id:)
      resource = query_service.find_by(id: Valkyrie::ID.new(id))
      preservation_object = Wayfinder.for(resource).try(:preservation_object)
      return unless preservation_object
      topic = pubsub.topic(pubsub_topic)
      topic.publish do |publisher|
        queue_resources([preservation_object], publisher)
      end
      Rails.logger.info "Enqueued PreservationObject #{preservation_object.id} for Cloud Fixity Checking"
    end

    def self.queue_resources(resources, publisher)
      # resources.each do |resource|
      #   publish_file_metadata(resource, resource.metadata_node, publisher, :metadata_node) if resource.metadata_node.present?
      #   resource.binary_nodes.each do |binary_node|
      #     publish_file_metadata(resource, binary_node, publisher, :binary_nodes)
      #   end
      # end
    end

    def self.publish_file_metadata(resource, file_metadata, publisher, child_property)
      file_identifier = file_metadata.file_identifiers.first
      md5 = file_metadata.checksum.first&.md5
      return unless file_identifier && md5
      publisher.publish(
        {
          md5: md5,
          cloudPath: file_identifier.to_s.gsub(/.*\/\//, ""),
          preservation_object_id: resource.id.to_s,
          file_metadata_node_id: file_metadata.id.to_s,
          child_property: child_property.to_s
        }.to_json
      )
    end

    def self.query_service
      Valkyrie::MetadataAdapter.find(:postgres).query_service
    end
  end
end
