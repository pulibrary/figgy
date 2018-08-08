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
      raise Valkyrie::Persistence::StaleObjectError, resource.id unless valid_lock?(resource)
      internal_resource = resource.dup

      internal_resource = generate_id(internal_resource) if internal_resource.id.blank?
      internal_resource.created_at ||= Time.current
      internal_resource.updated_at = Time.current
      generate_lock_token(internal_resource)
      bag_factory.new(resource: internal_resource).create!
      internal_resource.new_record = false
      internal_resource
    end

    def save_all(resources:)
      resources.map do |resource|
        save(resource: resource)
      end
    rescue Valkyrie::Persistence::StaleObjectError
      # Re-raising with no error message to prevent confusion
      raise Valkyrie::Persistence::StaleObjectError
    end

    def delete(resource:)
      bag_factory.new(resource: resource).delete!
    end

    def wipe!
      FileUtils.rm_rf(adapter.base_path)
    end

    private

      def valid_lock?(resource)
        return true if resource.id.blank?
        return true unless resource.optimistic_locking_enabled?

        cached_resource = adapter.query_service.find_by(id: resource.id)
        return true if cached_resource.blank?

        resource_lock_tokens = resource[Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK]
        resource_value = resource_lock_tokens.find { |lock_token| lock_token.adapter_id == adapter.id }
        return true if resource_value.blank?

        cached_value = cached_resource[Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK].first
        cached_value == resource_value
      rescue Valkyrie::Persistence::ObjectNotFoundError
        true
      end

      def generate_id(resource)
        resource.new(id: SecureRandom.uuid)
      end

      def generate_lock_token(resource)
        return unless resource.optimistic_locking_enabled?
        token = Valkyrie::Persistence::OptimisticLockToken.new(adapter_id: adapter.id, token: Time.now.to_f)
        resource.send("#{Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK}=", token)
      end
  end
end
