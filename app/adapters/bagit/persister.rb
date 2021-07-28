# frozen_string_literal: true
module Bagit
  class Persister
    attr_reader :adapter
    delegate :bag_factory, :query_service, to: :adapter
    def initialize(adapter:)
      @adapter = adapter
    end

    def save(resource:, external_resource: false)
      # save
      raise Valkyrie::Persistence::StaleObjectError, "The object #{resource.id} has been updated by another process." unless valid_lock?(resource)
      raise Valkyrie::Persistence::ObjectNotFoundError, "The object #{resource.id} is previously persisted but not found at save time." unless external_resource || valid_for_save?(resource)
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
      raise Valkyrie::Persistence::StaleObjectError, "One or more resources have been updated by another process."
    end

    def valid_for_save?(resource)
      return true unless resource.persisted? # a new resource
      query_service.find_by(id: resource.id).present? # a persisted resource must be found
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

        resource_lock_tokens = resource[Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK]
        resource_value = resource_lock_tokens.find { |lock_token| lock_token.adapter_id == adapter.id }
        return true if resource_value.blank?

        cached_resource = adapter.query_service.find_by(id: resource.id)
        return true if cached_resource.blank?

        cached_value = cached_resource[Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK].first
        cached_value == resource_value
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
