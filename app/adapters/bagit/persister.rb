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
      ensure_multiple_values!(resource)
      bag_factory.new(resource: resource).create!
      resource.new_record = false
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

      def ensure_multiple_values!(resource)
        bad_keys = resource.attributes.except(:internal_resource, :created_at, :updated_at, :new_record, :id).select do |_k, v|
          !v.nil? && !v.is_a?(Array)
        end
        raise ::Valkyrie::Persistence::UnsupportedDatatype, "#{resource}: #{bad_keys.keys} have non-array values, which can not be persisted by Valkyrie. Cast to arrays." unless bad_keys.keys.empty?
      end
  end
end
