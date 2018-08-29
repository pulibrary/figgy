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
<<<<<<< HEAD
      raise Valkyrie::Persistence::StaleObjectError, "The object #{resource.id} has been updated by another process." unless valid_lock?(resource)
      internal_resource = resource.dup

      internal_resource = generate_id(internal_resource) if internal_resource.id.blank?
      internal_resource.created_at ||= Time.current
      internal_resource.updated_at = Time.current
      generate_lock_token(internal_resource)
      bag_factory.new(resource: internal_resource).create!
      internal_resource.new_record = false
      internal_resource
=======
      resource = generate_id(resource) if resource.id.blank?
      resource.created_at ||= Time.current
      resource.updated_at = Time.current
      ensure_multiple_values!(resource)
      bag_factory.new(resource: resource).create!
      resource.new_record = false
      resource
>>>>>>> d8616123... adds lux order manager to figgy
    end

    def save_all(resources:)
      resources.map do |resource|
        save(resource: resource)
      end
<<<<<<< HEAD
    rescue Valkyrie::Persistence::StaleObjectError
      # Re-raising with no error message to prevent confusion
      raise Valkyrie::Persistence::StaleObjectError, "One or more resources have been updated by another process."
=======
>>>>>>> d8616123... adds lux order manager to figgy
    end

    def delete(resource:)
      bag_factory.new(resource: resource).delete!
    end

    def wipe!
      FileUtils.rm_rf(adapter.base_path)
    end

    private

<<<<<<< HEAD
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
      end

=======
>>>>>>> d8616123... adds lux order manager to figgy
      def generate_id(resource)
        resource.new(id: SecureRandom.uuid)
      end

<<<<<<< HEAD
      def generate_lock_token(resource)
        return unless resource.optimistic_locking_enabled?
        token = Valkyrie::Persistence::OptimisticLockToken.new(adapter_id: adapter.id, token: Time.now.to_f)
        resource.send("#{Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK}=", token)
=======
      def ensure_multiple_values!(resource)
        bad_keys = resource.attributes.except(:internal_resource, :created_at, :updated_at, :new_record, :id).select do |_k, v|
          !v.nil? && !v.is_a?(Array)
        end
        raise ::Valkyrie::Persistence::UnsupportedDatatype, "#{resource}: #{bad_keys.keys} have non-array values, which can not be persisted by Valkyrie. Cast to arrays." unless bad_keys.keys.empty?
>>>>>>> d8616123... adds lux order manager to figgy
      end
  end
end
