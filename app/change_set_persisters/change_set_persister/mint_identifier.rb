# frozen_string_literal: true
class ChangeSetPersister
  class MintIdentifier
    attr_reader :change_set_persister, :change_set
    def initialize(change_set_persister:, change_set:, post_save_resource: nil)
      @change_set = change_set
      @change_set_persister = change_set_persister
    end

    def run
      return unless change_set.resource.respond_to?(:identifier)
      return unless change_set.resource.decorate.ark_mintable_state?
      return unless needs_updating?(change_set)

      mint_identifier
      change_set
    end

    private

      def mint_identifier
        identifier_service.mint_or_update(resource: change_set.model)
      end

      # Determine whether or not the changes being persisted include the
      # resource being published
      # @param change_set [ChangeSet]
      # @return [Boolean]
      def published?(change_set)
        change_set.changed?(:state) && change_set.resource.decorate.public_readable_state?
      end

      # Determine whether or not the changes being persisted include an updated
      # title for an already published resource
      # @param change_set [ChangeSet]
      # @return [Boolean]
      def published_with_new_title?(change_set)
        change_set.resource.decorate.public_readable_state? && change_set.changed?(:title)
      end

      # Determine whether or not the changes being persisted necessitate the
      # minting of a new identifier for the resource (or, the updating of ARK
      # metadata for the resource [e. g. the ARK target or title of the resource])
      # @param change_set [ChangeSet]
      # @return [Boolean]
      def needs_updating?(change_set)
        # Always mint/update the ARK unless the resource already has an identifier
        return true unless change_set.resource.try(:identifier)
        # Only update under the following conditions:
        # - The resource has been published with a new identifier
        # - The source metadata identifier has changed
        published?(change_set) || published_with_new_title?(change_set) || change_set.changed?(:source_metadata_identifier)
      end

      def identifier_service
        return IdentifierService::Mock if Rails.env.development?
        IdentifierService
      end
  end
end
