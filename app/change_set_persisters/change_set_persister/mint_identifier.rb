# frozen_string_literal: true
class ChangeSetPersister
  class MintIdentifier
    attr_reader :change_set_persister, :change_set
    def initialize(change_set_persister:, change_set:, post_save_resource: nil)
      @change_set = change_set
      @change_set_persister = change_set_persister
    end

    def run
      return unless change_set.resource.decorate.ark_mintable_state?
<<<<<<< HEAD
      return unless needs_updating?(change_set)
=======
>>>>>>> d8616123... adds lux order manager to figgy

      mint_identifier
      change_set
    end

    private

      def mint_identifier
        identifier_service.mint_or_update(resource: change_set.model)
      end

<<<<<<< HEAD
      def needs_updating?(change_set)
        return true unless change_set.resource.identifier
        change_set.state_changed? || change_set.changed?(:title) || change_set.changed?(:source_metadata_identifier)
      end

=======
>>>>>>> d8616123... adds lux order manager to figgy
      def identifier_service
        IdentifierService
      end
  end
end
