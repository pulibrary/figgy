# frozen_string_literal: true
class PlumChangeSetPersister
  class MintIdentifier
    attr_reader :change_set_persister, :change_set
    def initialize(change_set_persister:, change_set:, post_save_resource: nil)
      @change_set = change_set
      @change_set_persister = change_set_persister
    end

    def run
      return unless change_set.resource.decorate.ark_mintable_state?

      mint_identifier
      change_set
    end

    private

      def mint_identifier
        identifier_service.mint_or_update(resource: change_set.model)
      end

      def identifier_service
        IdentifierService
      end
  end
end
