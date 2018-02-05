# frozen_string_literal: true
module Bagit
  class Persister
    attr_reader :adapter
    delegate :bag_factory, to: :adapter
    def initialize(adapter:)
      @adapter = adapter
    end

    def save(resource:)
      # save
      resource = generate_id(resource) if resource.id.blank?
      resource.created_at ||= Time.current
      resource.updated_at = Time.current
      bag_factory.new(resource: resource).create!
      resource
    end

    def save_all(resources:)
      resources.map do |resource|
        save(resource: resource)
      end
    end

    def delete(resource:)
      bag_factory.new(resource: resource).delete!
    end

    def wipe!
      FileUtils.rm_rf(adapter.base_path)
    end

    private

      def generate_id(resource)
        resource.new(id: SecureRandom.uuid)
      end
  end
end
