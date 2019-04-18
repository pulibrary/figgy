# frozen_string_literal: true
module CloudFixity
  require "google/cloud/pubsub"
  class Worker
    def self.pubsub
      @pubsub ||= begin
                    Google::Cloud::Pubsub.new
                  end
    end

    def self.pubsub_topic
      @pubsub_topic ||= Figgy.config["fixity_status_topic"]
    end

    def self.pubsub_subscription
      @pubsub_subscription ||= Figgy.config["fixity_status_topic"]
    end

    def self.run!
      Rails.logger.info "Running worker to check for fixity updating"

      topic = pubsub.topic(pubsub_topic)
      subscription = topic.subscription(pubsub_subscription)

      subscriber = subscription.listen do |message|
        message.acknowledge!
        data = JSON.parse(message.data.to_s, symbolize_names: true)
        UpdateFixityJob.perform_later(data)
      end

      # Start background threads that will call block passed to listen.
      subscriber.start

      # Fade into a deep sleep as worker will run indefinitely
      sleep
    end
  end
end
